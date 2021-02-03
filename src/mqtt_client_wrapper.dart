import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef PayloadReceivedhandler = void Function(String payload);

class MqttClientWrapper {

  MqttClientWrapper() {
    final Map<String, String> envVars = Platform.environment;

    final String mqttHost = envVars['MQTT_HOST'] ?? '127.0.0.1';
    final int mqttPort = int.tryParse(envVars['MQTT_PORT'] ?? '1883') ?? 1883;
    _baseTopic = envVars['MQTT_BASE_TOPIC'] ?? 'leaf';

    _mqttClient = MqttServerClient.withPort(mqttHost, 'leaf2mqtt', mqttPort);
  }

  MqttServerClient _mqttClient;
  String _baseTopic;
  final AsciiPayloadConverter _converter = AsciiPayloadConverter();

  final Map<String, List<PayloadReceivedhandler>> _payloadReceivedHandlers = <String, List<PayloadReceivedhandler>>{};

  ConnectCallback onConnected;

  DisconnectCallback onDisconnected;

  Future<void> connectWithRetry(String mqttUser, String mqttPassword) async {
    _mqttClient.onConnected = onConnected;

    // Set to null to prevent multiple connectWithRetry
    // calls since onDisconnected is called when a connection fails.
    _mqttClient.onDisconnected = null;

    bool connected = false;
    while (!connected) {
      try {
        final MqttClientConnectionStatus connectionCode  = await _mqttClient.connect(mqttUser, mqttPassword);
        print('Mqtt connection code: ' + connectionCode.returnCode.toString());
        connected = connectionCode.returnCode == MqttConnectReturnCode.connectionAccepted;
      } catch (e){
        print(e);
      }

      if(connected){
        _mqttClient.onDisconnected = () => connectWithRetry(mqttUser, mqttPassword);
      } else {
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  void subscribeToCommandTopic() {
    _mqttClient.subscribe('$_baseTopic/command/#', MqttQos.exactlyOnce);
    _mqttClient.subscribe('$_baseTopic/+/command/#', MqttQos.exactlyOnce);
    _mqttClient.updates.listen(_receiveData);
  }

  void subscribeTopic(String topic, PayloadReceivedhandler handler){
    _payloadReceivedHandlers.update(
      '$_baseTopic/$topic',
      (List<PayloadReceivedhandler> handlers) { handlers.add(handler); return handlers; },
      ifAbsent: () => <PayloadReceivedhandler> [handler]);
  }

  void publishMessage(String topic, String value) {
    if (!(topic?.isEmpty ?? true) && !(value?.isEmpty ?? true) )
    {
      try {
        _mqttClient.publishMessage(
          '$_baseTopic/$topic',
          MqttQos.atLeastOnce,
          _converter.convertToBytes(value), retain: true);
      } on ConnectionException catch (_) {
        // does not matter, we will send back latest states on reconnect.
      }
    }
  }

  void _receiveData(List<MqttReceivedMessage<MqttMessage>> messages) {
    // Using fromList because I am not able to create a Uint8Buffer for some reason.
    final MqttByteBuffer byteBuffer = MqttByteBuffer.fromList(List<int>.empty());
    for (final MqttReceivedMessage<MqttMessage> message in messages) {
      message.payload.writeTo(byteBuffer);
      final String payloadWithTopic = MqttPublishPayload.bytesToStringAsString(byteBuffer.buffer);
      final String payload =
        payloadWithTopic.substring(payloadWithTopic.indexOf(message.topic) + message.topic.length);

      final List<PayloadReceivedhandler> handlers =
        _payloadReceivedHandlers[message.topic] ?? List<PayloadReceivedhandler>.empty();
      for (final PayloadReceivedhandler handler in handlers) {
        handler(payload);
      }
    }
  }
}
