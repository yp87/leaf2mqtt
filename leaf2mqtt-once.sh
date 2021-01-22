#!/bin/bash

sleep 10
echo "Running one-shot update..."
cd /root
if [ -z "$MQTTUSER" ]
then
    ./leaf2mqtt.exe --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC > cmd.sh
else
    ./leaf2mqtt.exe --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC --mqttuser=$MQTTUSER --mqttpass=$MQTTPASS > cmd.sh
fi
chmod +x cmd.sh
echo "Publishing responses after command..."
./cmd.sh

