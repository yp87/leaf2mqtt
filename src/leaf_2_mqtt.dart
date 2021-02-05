import 'dart:async';
import 'dart:io';

import 'leaf/leaf_session.dart';
import 'leaf/leaf_vehicle.dart';
import 'mqtt_client_wrapper.dart';

LeafSession _session;
Future<void> main() async {
  final Map<String, String> envVars = Platform.environment;

  final String leafTypeStr = envVars['LEAF_TYPE'] ?? 'oldUSA';
  final LeafType leafType =
    LeafType.values.firstWhere(
      (LeafType e) => e.toString().toLowerCase().endsWith(leafTypeStr.toLowerCase()),
      orElse: () => null);

  if (leafType == null) {
    final String leafTypes = LeafType.values.toString();
    print('LEAF_TYPE environment variable must be set to a valid value from: $leafTypes');
    exit(2);
  }

  _session = LeafSessionFactory.createLeafSession(leafType);

  await _login();

  final MqttClientWrapper mqttClient = MqttClientWrapper();
  mqttClient.onConnected = () => _onConnected(mqttClient);
  mqttClient.connectWithRetry(envVars['MQTT_USERNAME'], envVars['MQTT_PASSWORD']);

  // Starting one loop per vehicle because each can have different interval depending on their state.
  await Future.wait(_session.vehicles.map((Vehicle vehicle) => startUpdateLoop(mqttClient, vehicle)));
}

bool _loggingIn = false;
Future<void> _login() async {
  if (_loggingIn) {
    return;
  }

  _loggingIn = true;

  final Map<String, String> envVars = Platform.environment;

  final String leafUser = envVars['LEAF_USERNAME'];
  final String leafPassword = envVars['LEAF_PASSWORD'];

  if ((leafUser?.isEmpty ?? true) || (leafPassword?.isEmpty ?? true)) {
    print('LEAF_USER and LEAF_PASSWORD environment variables must be set.');
    exit(1);
  }

  bool loggedIn = false;
  while(!loggedIn) {
    try {
      await _session.login(leafUser, leafPassword);
      print('Login successful');
      loggedIn = true;
      _loggingIn = false;
    } catch (e, stacktrace) {
      print('An error occured while logging in. Please make sure you have selected the right LEAF_TYPE, LEAF_USERNAME and LEAF_PASSWORD.');
      print(e);
      print(stacktrace);
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }
}

Future<void> startUpdateLoop(MqttClientWrapper mqttClient, Vehicle vehicle) async {
  final Map<String, String> envVars = Platform.environment;
  final int updateIntervalMinutes = int.tryParse(envVars['UPDATE_INTERVAL_MINUTES']  ?? '60') ?? 60;
  final int chargingUpdateIntervalMinutes = int.tryParse(envVars['CHARGING_UPDATE_INTERVAL_MINUTES'] ?? '15') ?? 15;

  subscribeToCommands(mqttClient, vehicle);

  while (true) {
    await fetchAndPublishAllStatus(mqttClient, vehicle);

    int calculatedUpdateIntervalMinutes = updateIntervalMinutes;
    if (vehicle.isCharging && chargingUpdateIntervalMinutes < calculatedUpdateIntervalMinutes) {
      calculatedUpdateIntervalMinutes = chargingUpdateIntervalMinutes;
    }

    await Future<void>.delayed(Duration(minutes: calculatedUpdateIntervalMinutes));
  }
}

void subscribeToCommands(MqttClientWrapper mqttClient, Vehicle vehicle) {
  void subscribe(String topic, void Function(String payload) handler) {
    mqttClient.subscribeTopic('${vehicle.vin}/$topic', handler);

    if (_session.vehicles[0].vin == vehicle.vin) {
      // first vehicle also can send command without the vin
      mqttClient.subscribeTopic(topic, handler);
    }
  }

  subscribe('command', (String payload) {
      switch (payload) {
        case 'update':
            fetchAndPublishAllStatus(mqttClient, vehicle);
          break;
        default:
      }
    });

  subscribe('command/battery', (String payload) {
      switch (payload) {
        case 'update':
            fetchAndPublishBatteryStatus(mqttClient, vehicle);
          break;
        case 'startCharging':
            _executeWithRetry(() => vehicle.startCharging().then(
              (_) => Future<void>.delayed(const Duration(seconds: 5)).then(
                (_) => fetchAndPublishBatteryStatus(mqttClient, vehicle))));
          break;
        default:
      }
    });

  subscribe('command/climate', (String payload) {
    switch (payload) {
      case 'update':
          fetchAndPublishClimateStatus(mqttClient, vehicle);
        break;
      case 'stop':
          _executeWithRetry(() => vehicle.stopClimate().then(
            (_) => Future<void>.delayed(const Duration(seconds: 5)).then(
              (_) => fetchAndPublishClimateStatus(mqttClient, vehicle))));
        break;
      default:
        if (payload?.startsWith('start') ?? false) {
          int targetTemperatureCelsius;

          String targetTemperature = payload.replaceFirst('start', '').trim();
          if (targetTemperature.startsWith('C')) {
            targetTemperature = targetTemperature.replaceFirst('C', '').trim();
            targetTemperatureCelsius = double.tryParse(targetTemperature)?.round();

          } else if (targetTemperature.startsWith('F')) {
            targetTemperature = targetTemperature.replaceFirst('F', '').trim();
            final int targetTemperatureFahrenheit = double.tryParse(targetTemperature)?.round();

            if (targetTemperatureFahrenheit != null) {
              targetTemperatureCelsius = ((targetTemperatureFahrenheit - 32) * 5 / 9).round();
            }
          } else if (payload == 'start') {
            targetTemperatureCelsius = 21;
          }

          if (targetTemperatureCelsius != null){
            _executeWithRetry(() => vehicle.startClimate(targetTemperatureCelsius).then(
              (_) => Future<void>.delayed(const Duration(seconds: 5)).then(
                (_) => fetchAndPublishClimateStatus(mqttClient, vehicle))));
          }
        }
        break;
    }
  });
}

Future<void> fetchAndPublishBatteryStatus(MqttClientWrapper mqttClient, Vehicle vehicle) =>
   _executeWithRetry(() => vehicle.fetchBatteryStatus().then(mqttClient.publishStates));

Future<void> fetchAndPublishClimateStatus(MqttClientWrapper mqttClient, Vehicle vehicle) =>
   _executeWithRetry(() => vehicle.fetchClimateStatus().then(mqttClient.publishStates));

Future<void> fetchAndPublishAllStatus(MqttClientWrapper mqttClient, Vehicle vehicle) =>
  Future.wait(<Future<void>> [
    Future<void>(() => mqttClient.publishStates(vehicle.getVehicleStatus())),
    fetchAndPublishBatteryStatus(mqttClient, vehicle),
    fetchAndPublishClimateStatus(mqttClient, vehicle)
  ]);

void _onConnected(MqttClientWrapper mqttClient) {
  mqttClient.subscribeToCommandTopic();
  mqttClient.publishStates(_session.getAllLastKnownStatus());
}

extension on MqttClientWrapper {
  void publishStates(Map<String, String> states) {
    states.forEach(publishMessage);
  }
}

typedef Executable = Future<void> Function();
Future<void> _executeWithRetry(Executable executable) async {
  try {
    await _execute(executable);
  } catch (_) {
    try {
      // retry 1 time..
      await Future<void>.delayed(const Duration(seconds: 5));
      await _execute(executable);
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
      print('force a login');
      _login();
    }
  }
}

Future<void> _execute(Executable executable) => executable();
