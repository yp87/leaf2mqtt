import 'dart:async';
import 'dart:io';

import 'leaf/leaf_session.dart';
import 'leaf/leaf_vehicle.dart';
import 'mqtt_client_wrapper.dart';

Future<void> main() async {
  final Map<String, String> envVars = Platform.environment;

  final String leafUser = envVars['LEAF_USERNAME'];
  final String leafPassword = envVars['LEAF_PASSWORD'];

  if ((leafUser?.isEmpty ?? true) || (leafPassword?.isEmpty ?? true)) {
    print('LEAF_USER and LEAF_PASSWORD environment variables must be set.');
    exit(1);
  }

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

  final LeafSession session = LeafSessionFactory.createLeafSession(leafType);

  try {
    await session.login(leafUser, leafPassword);
  } catch (e, stacktrace) {
    print('An error occured while logging in. Please make sure you have selected the right LEAF_TYPE, LEAF_USERNAME and LEAF_PASSWORD.');
    print(e);
    print(stacktrace);
    exit(3);
  }

  final MqttClientWrapper mqttClient = MqttClientWrapper();
  mqttClient.onConnected = () => _onConnected(mqttClient, session);

  // Starting one loop per vehicle because each can have different interval depending on their state.
  await Future.wait(session.vehicles.map((Vehicle vehicle) => startUpdateLoop(session, mqttClient, vehicle.vin)));
}

Future<void> startUpdateLoop(LeafSession session, MqttClientWrapper mqttClient, String vin) async {
  final Map<String, String> envVars = Platform.environment;
  final int updateIntervalMinutes = int.tryParse(envVars['UPDATE_INTERVAL_MINUTES']  ?? '60') ?? 60;
  final int chargingUpdateIntervalMinutes = int.tryParse(envVars['CHARGING_UPDATE_INTERVAL_MINUTES'] ?? '15') ?? 15;

  final Vehicle vehicle =
  session.vehicles.firstWhere((Vehicle vehicle) => vehicle.vin == vin, orElse: () => null);

  if (vehicle == null) {
    print('Did not found vehicle with vin $vin');
    return;
  }

  void subscribe(String topic, void Function(String payload) handler) {
    mqttClient.subscribeTopic('$vin/$topic', handler);

    if (session.vehicles[0].vin == vin) {
      // first vehicle also can send command without the vin
      mqttClient.subscribeTopic(topic, handler);
    }
  }

  Completer<void> forceUpdateAllCompleter;
  subscribe('command', (String payload) {
      switch (payload) {
        case 'update':
            forceUpdateAllCompleter?.complete();
          break;
        default:
      }
    });

  while (true) {
    mqttClient.publishStates(vehicle.lastVehicleStatus);

    final List<Future<void>> fetchFutures = <Future<void>>[];

    fetchFutures.add(
      vehicle.fetchBatteryStatus().then((_) => mqttClient.publishStates(vehicle.lastBatteryStatus)));

    await Future.wait(fetchFutures);

    int calculatedUpdateIntervalMinutes = updateIntervalMinutes;
    if (vehicle.isCharging && chargingUpdateIntervalMinutes < calculatedUpdateIntervalMinutes) {
      calculatedUpdateIntervalMinutes = chargingUpdateIntervalMinutes;
    }

    forceUpdateAllCompleter = Completer<void>();
    await Future.any(<Future<void>>
      [
        Future<void>.delayed(Duration(minutes: calculatedUpdateIntervalMinutes)),
        forceUpdateAllCompleter.future
      ]);
  }
}

void _onConnected(MqttClientWrapper mqttClient, LeafSession leafSession) {
  mqttClient.publishStates(leafSession.getAllLastKnownStatus());
}

extension on MqttClientWrapper {
  void publishStates(Map<String, String> states) {
    states.forEach(publishMessage);
  }
}
