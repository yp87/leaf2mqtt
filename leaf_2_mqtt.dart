import 'mqtt_client_wrapper.dart';
import 'package:dartnissanconnectna/dartnissanconnectna.dart';
import 'dart:io';

Future<void> main() async {
  var envVars = Platform.environment;

  var leafUser = envVars['LEAF_USERNAME'];
  var leafPassword = envVars['LEAF_PASSWORD'];

  if ((leafUser?.isEmpty ?? true) || (leafPassword?.isEmpty ?? true)) {
    print('LEAF_USER and LEAF_PASSWORD environment variables must be set.');
    exit(1);
  }  

  var leafRegion = envVars['LEAF_REGION'] ?? 'US';
  var updateIntervalMinutes = int.tryParse(envVars['UPDATE_INTERVAL_MINUTES']  ?? '60') ?? 60;
  var chargingUpdateIntervalMinutes = int.tryParse(envVars['CHARGING_UPDATE_INTERVAL_MINUTES'] ?? '15') ?? 15;

  NissanConnectSession session = new NissanConnectSession(debug: false);

  var generalStates = new Map<String, String>();
  var batteryStates = new Map<String, String>();
  var allStates = [generalStates, batteryStates];

  var mqttClient = new MqttClientWrapper();
  mqttClient.onConnected = () => _onConnected(mqttClient, allStates);

  while (true) {
    var vehicle = await session.login(username: leafUser, password: leafPassword, countryCode: leafRegion);

    if (generalStates.isEmpty) {
      generalStates['nickname'] = vehicle.nickname;
      generalStates['vin'] = vehicle.vin;
      mqttClient.publishStates(generalStates);
    }

    var battery = await vehicle.requestBatteryStatus();
    batteryStates['battery/percentage'] = battery.batteryPercentage;
    batteryStates['battery/connected'] = battery.isConnected.toString();
    batteryStates['battery/charging'] = battery.isCharging.toString();
    batteryStates['battery/updated'] = DateTime.now().toUtc().toIso8601String();
    mqttClient.publishStates(batteryStates);

    var calculatedUpdateIntervalMinutes = updateIntervalMinutes;
    if (battery.isCharging && chargingUpdateIntervalMinutes < calculatedUpdateIntervalMinutes) {
      calculatedUpdateIntervalMinutes = chargingUpdateIntervalMinutes;
    }

    await Future.delayed(new Duration(minutes: calculatedUpdateIntervalMinutes));
  }
}

void _onConnected(MqttClientWrapper mqttClient, List<Map<String, String>> allStates) {
  mqttClient.publishAllStates(allStates);
}

extension on MqttClientWrapper {
  void publishAllStates(List<Map<String, String>> allStates) {
    allStates.forEach((states) => this.publishStates(states));
  }

  void publishStates(Map<String, String> states) {
    states..forEach((key, value) => this.publishMessage(key, value));
  }
}
