import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttClientWrapper {

  MqttClientWrapper() {
    final Map<String, String> envVars = Platform.environment;

    final String mqttHost = envVars['MQTT_HOST'] ?? '127.0.0.1';
    final int mqttPort = int.tryParse(envVars['MQTT_PORT'] ?? '1883') ?? 1883;
    final String mqttUser = envVars['MQTT_USERNAME'];
    final String mqttPassword = envVars['MQTT_PASSWORD'];
    _baseTopic = envVars['MQTT_BASE_TOPIC'] ?? 'leaf';

    _mqttClient = MqttServerClient.withPort(mqttHost, 'leaf2mqtt', mqttPort);
    _mqttClient.autoReconnect = true;
    _mqttClient.onConnected = onConnected;
    _connectWithRetry(mqttUser, mqttPassword);
  }

  MqttServerClient _mqttClient;
  String _baseTopic;
  final AsciiPayloadConverter _converter = AsciiPayloadConverter();

  ConnectCallback onConnected;

  Future<void> _connectWithRetry(String mqttUser, String mqttPassword) async {
    bool connected = false;
    while (!connected) {
      try {
        final MqttClientConnectionStatus connectionCode  = await _mqttClient.connect(mqttUser, mqttPassword);
        print('Mqtt connection code: ' + connectionCode.returnCode.toString());
        connected = connectionCode.returnCode == MqttConnectReturnCode.connectionAccepted;
      } on Exception catch (e){
        print(e);
      }

      if(!connected){
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  void publishMessage(String topic, String value) {
    if (!(topic?.isEmpty ?? true) && !(value?.isEmpty ?? true) )
    {
      try {
        _mqttClient.publishMessage('$_baseTopic/$topic', MqttQos.atLeastOnce, _converter.convertToBytes(value), retain: true);
      } on ConnectionException catch (_) {
        // does not matter, we will send back latest states on reconnect.
      }
    }
  }
}
