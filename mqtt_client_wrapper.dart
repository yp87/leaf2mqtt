import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';

class MqttClientWrapper {
  MqttServerClient _mqttClient;
  String _baseTopic;
  var _converter = new AsciiPayloadConverter();

  ConnectCallback onConnected;

  MqttClientWrapper() {
    var envVars = Platform.environment;
    
    var mqttHost = envVars['MQTT_HOST'] ?? '127.0.0.1';
    var mqttPort = int.tryParse(envVars['MQTT_PORT'] ?? '1883') ?? 1883;
    var mqttUser = envVars['MQTT_USERNAME'];
    var mqttPassword = envVars['MQTT_PASSWORD'];
    _baseTopic = envVars['MQTT_BASE_TOPIC'] ?? 'leaf';

    _mqttClient = MqttServerClient.withPort(mqttHost, 'leaf2mqtt', mqttPort);
    _mqttClient.autoReconnect = true;
    _mqttClient.onConnected = onConnected;
    _connectWithRetry(mqttUser, mqttPassword);
  }

  Future<void> _connectWithRetry(String mqttUser, mqttPassword) async {  
    bool connected = false; 
    while (!connected) {
      try { 
        var a = await _mqttClient.connect(mqttUser, mqttPassword);
        print('Mqtt connection code: ' + a.returnCode.toString());
        connected = a.returnCode == MqttConnectReturnCode.connectionAccepted;
      } on Exception catch (e){
        print(e);
      }

      if(!connected){
        await Future.delayed(new Duration(seconds: 5));
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