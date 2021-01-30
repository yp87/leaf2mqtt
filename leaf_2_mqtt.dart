import 'dart:io';

import 'package:dartnissanconnectna/dartnissanconnectna.dart';

import 'mqtt_client_wrapper.dart';

Future<void> main() async {
  final Map<String, String> envVars = Platform.environment;

  final String leafUser = envVars['LEAF_USERNAME'];
  final String leafPassword = envVars['LEAF_PASSWORD'];

  if ((leafUser?.isEmpty ?? true) || (leafPassword?.isEmpty ?? true)) {
    print('LEAF_USER and LEAF_PASSWORD environment variables must be set.');
    exit(1);
  }

  final String leafRegion = envVars['LEAF_REGION'] ?? 'US';
  final int updateIntervalMinutes = int.tryParse(envVars['UPDATE_INTERVAL_MINUTES']  ?? '60') ?? 60;
  final int chargingUpdateIntervalMinutes = int.tryParse(envVars['CHARGING_UPDATE_INTERVAL_MINUTES'] ?? '15') ?? 15;

  final NissanConnectSession session = NissanConnectSession(debug: false);

  final Map<String, String> generalStates = <String, String>{};
  final Map<String, String> batteryStates = <String, String>{};
  final List<Map<String, String>> allStates = <Map<String, String>>[generalStates, batteryStates];

  final MqttClientWrapper mqttClient = MqttClientWrapper();
  mqttClient.onConnected = () => _onConnected(mqttClient, allStates);

  while (true) {
    final NissanConnectVehicle vehicle = await session.login(username: leafUser, password: leafPassword, countryCode: leafRegion);

    if (generalStates.isEmpty) {
      generalStates['nickname'] = vehicle.nickname.toString();
      generalStates['vin'] = vehicle.vin.toString();
      mqttClient.publishStates(generalStates);
    }

    final NissanConnectBattery battery = await vehicle.requestBatteryStatus();
    batteryStates['battery/percentage'] = battery.batteryPercentage;
    batteryStates['battery/connected'] = battery.isConnected.toString();
    batteryStates['battery/charging'] = battery.isCharging.toString();
    batteryStates['battery/updated'] = DateTime.now().toUtc().toIso8601String();
    mqttClient.publishStates(batteryStates);

    int calculatedUpdateIntervalMinutes = updateIntervalMinutes;
    if (battery.isCharging && chargingUpdateIntervalMinutes < calculatedUpdateIntervalMinutes) {
      calculatedUpdateIntervalMinutes = chargingUpdateIntervalMinutes;
    }

    await Future<void>.delayed(Duration(minutes: calculatedUpdateIntervalMinutes));
  }
}

void _onConnected(MqttClientWrapper mqttClient, List<Map<String, String>> allStates) {
  mqttClient.publishAllStates(allStates);
}

extension on MqttClientWrapper {
  void publishAllStates(List<Map<String, String>> allStates) {
    allStates.forEach(publishStates);
  }

  void publishStates(Map<String, String> states) {
    states.forEach(publishMessage);
  }
}
