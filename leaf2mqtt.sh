#!/bin/bash

FIRST=1

echo "Starting up..."
cd /root
while true
do
    if [ -z "$MQTTUSER" ]
    then
        ./leaf2mqtt.exe --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC > cmd.sh
    else
        ./leaf2mqtt.exe --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC --mqttuser=$MQTTUSER --mqttpass=$MQTTPASS > cmd.sh
    fi
    chmod +x cmd.sh
    echo "Publishing responses..."
    ./cmd.sh
    if [ "$FIRST" -eq "1" ]
    then
        echo "Firing up MQTT listener..."
        ./listener.sh &
        FIRST=0
    fi
    if grep --quiet "/connected\" -m \"true\"" cmd.sh; then
        if grep --quiet "/charging\" -m \"true\"" cmd.sh; then
            echo "Sleeping for 5 mins"
            sleep 300
        else
            echo "Sleeping for 10 mins"
            sleep 600
        fi
    else
        echo "Sleeping for 2 hours"
        sleep 7200
    fi
done

