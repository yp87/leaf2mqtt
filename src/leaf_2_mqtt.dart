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
  await Future.wait(session.vehicles.map((Vehicle vehicle) => startUpdateLoop(session, mqttClient, vehicle)));
}

Future<void> startUpdateLoop(LeafSession session, MqttClientWrapper mqttClient, Vehicle vehicle) async {
  final Map<String, String> envVars = Platform.environment;
  final int updateIntervalMinutes = int.tryParse(envVars['UPDATE_INTERVAL_MINUTES']  ?? '60') ?? 60;
  final int chargingUpdateIntervalMinutes = int.tryParse(envVars['CHARGING_UPDATE_INTERVAL_MINUTES'] ?? '15') ?? 15;

  subscribeToCommands(mqttClient, vehicle, session);

  while (true) {
    await fetchAndPublishAllStatus(mqttClient, vehicle);

    int calculatedUpdateIntervalMinutes = updateIntervalMinutes;
    if (vehicle.isCharging && chargingUpdateIntervalMinutes < calculatedUpdateIntervalMinutes) {
      calculatedUpdateIntervalMinutes = chargingUpdateIntervalMinutes;
    }

    await Future<void>.delayed(Duration(minutes: calculatedUpdateIntervalMinutes));
  }
}

void subscribeToCommands(MqttClientWrapper mqttClient, Vehicle vehicle, LeafSession session) {
  void subscribe(String topic, void Function(String payload) handler) {
    mqttClient.subscribeTopic('${vehicle.vin}/$topic', handler);

    if (session.vehicles[0].vin == vehicle.vin) {
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
        case 'charge':
            vehicle.startCharging().then(
              (_) => Future<void>.delayed(const Duration(seconds: 5)).then(
                (_) => fetchAndPublishBatteryStatus(mqttClient, vehicle)));
          break;
        default:
      }
    });
}

Future<void> fetchAndPublishBatteryStatus(MqttClientWrapper mqttClient, Vehicle vehicle) =>
   vehicle.fetchBatteryStatus().then((_) => mqttClient.publishStates(vehicle.lastBatteryStatus));

Future<void> fetchAndPublishAllStatus(MqttClientWrapper mqttClient, Vehicle vehicle) =>
  Future.wait([
    Future<void>(() => mqttClient.publishStates(vehicle.lastVehicleStatus)),
    fetchAndPublishBatteryStatus(mqttClient, vehicle)
  ]);

void _onConnected(MqttClientWrapper mqttClient, LeafSession leafSession) {
  mqttClient.publishStates(leafSession.getAllLastKnownStatus());
}

extension on MqttClientWrapper {
  void publishStates(Map<String, String> states) {
    states.forEach(publishMessage);
  }
}
