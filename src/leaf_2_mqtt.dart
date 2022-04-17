import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import 'leaf/leaf_session.dart';
import 'leaf/leaf_vehicle.dart';
import 'mqtt_client_wrapper.dart';

LeafSession _session;
int _commandAttempts = 2;
final Logger _log = Logger('main');

Future<void> main() async {
  final Map<String, String> envVars = Platform.environment;

  final String logLevelStr = envVars['LOG_LEVEL'] ?? '${Level.WARNING}';
  Level logLevel = Level.LEVELS.firstWhere(
      (Level level) => level.name.toLowerCase() == logLevelStr.toLowerCase(),
      orElse: () => null);

  if (logLevel == null) {
    print(
        'LOG_LEVEL environment variable should be set to a valid value from: ${Level.LEVELS}. Defaulting to Warning.');
    logLevel = Level.WARNING;
  }

  Logger.root.level = logLevel;
  Logger.root.onRecord.listen((LogRecord record) {
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  _log.severe('V0.10');

  final String leafUser = envVars['LEAF_USERNAME'];
  final String leafPassword = envVars['LEAF_PASSWORD'];

  if ((leafUser?.isEmpty ?? true) || (leafPassword?.isEmpty ?? true)) {
    _log.severe(
        'LEAF_USERNAME and LEAF_PASSWORD environment variables must be set.');
    exit(1);
  }

  final String leafTypeStr = envVars['LEAF_TYPE'] ?? 'oldUSA';
  final LeafType leafType = LeafType.values.firstWhere(
      (LeafType e) =>
          e.toString().toLowerCase().endsWith(leafTypeStr.toLowerCase()),
      orElse: () => null);

  if (leafType == null) {
    final String leafTypes = LeafType.values.toString();
    _log.severe(
        'LEAF_TYPE environment variable must be set to a valid value from: $leafTypes');
    exit(2);
  }

  _commandAttempts = int.tryParse(envVars['COMMAND_ATTEMPTS'] ?? '1') ?? 1;

  final MqttClientWrapper mqttClient = MqttClientWrapper();
  await mqttClient.connectWithRetry(
      envVars['MQTT_USERNAME'], envVars['MQTT_PASSWORD']);

  _session = createLeafSession(leafType, leafUser, leafPassword);
  _session.onExecutionError =
      (String vin) => _onExecutionError(mqttClient, vin);

  await _login(mqttClient);

  mqttClient.onConnected = () => _onConnected(mqttClient);
  _onConnected(mqttClient);

  // Starting one loop per vehicle because each can have different interval depending on their state.
  await Future.wait(_session.vehicles
      .map((Vehicle vehicle) => startUpdateLoop(mqttClient, vehicle.vin)));
}

Completer<void> _loginCompleter;
Future<void> _login(MqttClientWrapper mqttClient) async {
  if (_loginCompleter != null) {
    _log.fine('Already logging in, waiting...');
    // already logging in.. wait for it to complete.
    await _loginCompleter.future;
    return;
  }

  _log.info('Logging in.');
  _loginCompleter = Completer<void>();

  bool loggedIn = false;
  while (!loggedIn) {
    try {
      await _session.login();
      _log.info('Login successful');
      loggedIn = true;
      _loginCompleter.complete();
      _loginCompleter = null;
    } catch (e, stacktrace) {
      _log.warning(
          'An error occured while logging in. Please make sure you have selected the right LEAF_TYPE, LEAF_USERNAME and LEAF_PASSWORD. Retrying in 5 seconds.');
      _log.fine(e);
      _log.fine(stacktrace);
      _onExecutionError(mqttClient);
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }
}

Future<void> startUpdateLoop(MqttClientWrapper mqttClient, String vin) async {
  _log.info('Starting loop for $vin');
  final Map<String, String> envVars = Platform.environment;
  final int updateIntervalMinutes =
      int.tryParse(envVars['UPDATE_INTERVAL_MINUTES'] ?? '60') ?? 60;
  final int chargingUpdateIntervalMinutes =
      int.tryParse(envVars['CHARGING_UPDATE_INTERVAL_MINUTES'] ?? '15') ?? 15;

  subscribeToCommands(mqttClient, vin);

  while (true) {
    await fetchAndPublishAllStatus(mqttClient, vin);

    int calculatedUpdateIntervalMinutes = updateIntervalMinutes;
    if ((_session.executeSync((Vehicle vehicle) => vehicle.isCharging, vin) ??
            false) &&
        chargingUpdateIntervalMinutes < calculatedUpdateIntervalMinutes) {
      calculatedUpdateIntervalMinutes = chargingUpdateIntervalMinutes;
    }

    await Future<void>.delayed(
        Duration(minutes: calculatedUpdateIntervalMinutes));
    _log.finer('Loop delay of $calculatedUpdateIntervalMinutes ended for $vin');
  }
}

void subscribeToCommands(MqttClientWrapper mqttClient, String vin) {
  _log.info('Subscribing to commands for $vin');
  void subscribe(String topic, void Function(String payload) handler) {
    mqttClient.subscribeTopic('$vin/$topic', handler);

    if (_session.executeSync(
            (Vehicle vehicle) => vehicle.isFirstVehicle(), vin) ??
        false) {
      // first vehicle also can send command without the vin
      mqttClient.subscribeTopic(topic, handler);
    }
  }

  subscribe('command', (String payload) {
    switch (payload) {
      case 'update':
        fetchAndPublishAllStatus(mqttClient, vin);
        break;
      default:
    }
  });

  subscribe('command/battery', (String payload) {
    switch (payload) {
      case 'update':
        fetchAndPublishBatteryStatus(mqttClient, vin);
        break;
      case 'startcharging':
        _session
            .executeCommandWithRetry(
                (Vehicle vehicle) => vehicle.startCharging(),
                vin,
                _commandAttempts)
            .then((_) => Future<void>.delayed(const Duration(seconds: 5))
                .then((_) => fetchAndPublishBatteryStatus(mqttClient, vin)));
        break;
      default:
    }
  });

  subscribe('command/climate', (String payload) {
    switch (payload) {
      case 'update':
        fetchAndPublishClimateStatus(mqttClient, vin);
        break;
      case 'stop':
        _session
            .executeCommandWithRetry((Vehicle vehicle) => vehicle.stopClimate(),
                vin, _commandAttempts)
            .then((_) => Future<void>.delayed(const Duration(seconds: 5))
                .then((_) => fetchAndPublishClimateStatus(mqttClient, vin)));
        break;
      default:
        if (payload?.startsWith('start') ?? false) {
          int targetTemperatureCelsius;

          String targetTemperature = payload.replaceFirst('start', '').trim();
          if (targetTemperature.startsWith('c')) {
            targetTemperature = targetTemperature.replaceFirst('c', '').trim();
            targetTemperatureCelsius =
                double.tryParse(targetTemperature)?.round();
          } else if (targetTemperature.startsWith('f')) {
            targetTemperature = targetTemperature.replaceFirst('f', '').trim();
            final int targetTemperatureFahrenheit =
                double.tryParse(targetTemperature)?.round();

            if (targetTemperatureFahrenheit != null) {
              targetTemperatureCelsius =
                  ((targetTemperatureFahrenheit - 32) * 5 / 9).round();
            }
          } else if (payload == 'start') {
            targetTemperatureCelsius = 21;
          }

          if (targetTemperatureCelsius != null) {
            _session
                .executeCommandWithRetry(
                    (Vehicle vehicle) =>
                        vehicle.startClimate(targetTemperatureCelsius),
                    vin,
                    _commandAttempts)
                .then((_) => Future<void>.delayed(const Duration(seconds: 5))
                    .then(
                        (_) => fetchAndPublishClimateStatus(mqttClient, vin)));
          }
        }
        break;
    }
  });

  subscribe('command/stats/daily', (String payload) {
    if (payload.startsWith('update')) {
      final String targetDatePart = payload.replaceAll('update', '').trim();
      final DateTime targetDate =
          DateTime.tryParse(targetDatePart.toUpperCase()) ?? DateTime.now();
      fetchAndPublishDailyStats(mqttClient, vin, targetDate);
    }
  });

  subscribe('command/stats/monthly', (String payload) {
    if (payload.startsWith('update')) {
      final String targetDatePart = payload.replaceAll('update', '').trim();
      final DateTime targetDate =
          DateTime.tryParse(targetDatePart) ?? DateTime.now();
      fetchAndPublishMonthlyStats(mqttClient, vin, targetDate);
    }
  });

  subscribe('command/location', (String payload) {
    switch (payload) {
      case 'update':
        fetchAndPublishLocation(mqttClient, vin);
        break;
      default:
    }
  });

  subscribe('command/cockpitStatus', (String payload) {
    switch (payload) {
      case 'update':
        fetchAndPublishCockpitStatus(mqttClient, vin);
        break;
      default:
    }
  });
}

Future<void> fetchAndPublishDailyStats(
    MqttClientWrapper mqttClient, String vin, DateTime targetDay) {
  _log.finer('fetchAndPublishDailyStats for $vin');
  return _session
      .executeWithRetry(
          (Vehicle vehicle) => vehicle.fetchDailyStatistics(targetDay), vin)
      .then(mqttClient.publishStates);
}

Future<void> fetchAndPublishMonthlyStats(
    MqttClientWrapper mqttClient, String vin, DateTime targetMonth) {
  _log.finer('fetchAndPublishMonthlyStats for $vin');
  return _session
      .executeWithRetry(
          (Vehicle vehicle) => vehicle.fetchMonthlyStatistics(targetMonth), vin)
      .then(mqttClient.publishStates);
}

Future<void> fetchAndPublishBatteryStatus(
    MqttClientWrapper mqttClient, String vin) {
  _log.finer('fetchAndPublishBatteryStatus for $vin');
  return _session
      .executeWithRetry((Vehicle vehicle) => vehicle.fetchBatteryStatus(), vin)
      .then(mqttClient.publishStates);
}

Future<void> fetchAndPublishClimateStatus(
    MqttClientWrapper mqttClient, String vin) {
  _log.finer('fetchAndPublishClimateStatus for $vin');
  return _session
      .executeWithRetry((Vehicle vehicle) => vehicle.fetchClimateStatus(), vin)
      .then(mqttClient.publishStates);
}

Future<void> fetchAndPublishLocation(MqttClientWrapper mqttClient, String vin) {
  _log.finer('fetchAndPublishLocation for $vin');
  return _session
      .executeWithRetry((Vehicle vehicle) => vehicle.fetchLocation(), vin)
      .then(mqttClient.publishStates);
}

Future<void> fetchAndPublishCockpitStatus(
    MqttClientWrapper mqttClient, String vin) {
  _log.finer('fetchAndPublishCockpit for $vin');
  return _session
      .executeWithRetry((Vehicle vehicle) => vehicle.fetchCockpitStatus(), vin)
      .then(mqttClient.publishStates);
}

Future<void> fetchAndPublishAllStatus(
    MqttClientWrapper mqttClient, String vin) {
  _log.finer('fetchAndPublishAllStatus for $vin');
  return Future.wait(<Future<void>>[
    Future<void>(() => mqttClient.publishStates(_session.executeSync(
        (Vehicle vehicle) => vehicle.getVehicleStatus(), vin))),
    fetchAndPublishBatteryStatus(mqttClient, vin),
    fetchAndPublishClimateStatus(mqttClient, vin),
    fetchAndPublishLocation(mqttClient, vin),
    fetchAndPublishCockpitStatus(mqttClient, vin)
  ]);
}

void _onConnected(MqttClientWrapper mqttClient) {
  _log.info('MQTT connected.');
  mqttClient.subscribeToCommandTopic();
  mqttClient.publishStates(_session.getAllLastKnownStatus());
}

void _onExecutionError(MqttClientWrapper mqttClient, [String vin]) {
  _log.warning('Could not execute request.');
  final String errorDateTime = DateTime.now().toUtc().toIso8601String();
  mqttClient.publishMessage('lastErrorDateTimeUtc', errorDateTime);
  if (vin != null) {
    mqttClient.publishMessage('{vin}/lastErrorDateTimeUtc', errorDateTime);
  }
}

extension on MqttClientWrapper {
  void publishStates(Map<String, String> states) {
    if (states != null) {
      _log.finest('publishStates ${states.toString()}');
      states.forEach(publishMessage);
    }
  }

  // void publishStatesJSON(Map<String, String> states) {
  //   if (states != null) {
  //     _log.finest('publishStates ${json.encode(states.toString())}');
  //     states.forEach(publishMessage);
  //   }
  // }
}
