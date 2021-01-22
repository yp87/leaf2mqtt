#!/bin/bash

VIN=`head -n 1 vin.txt`

if [ -z "$MQTTUSER" ]
then
    EXTRAS=""
else
    EXTRAS="-u \"$MQTTUSER\" -P \"$MQTTPASS\""
fi

while true
do
    mosquitto_sub -h "$MQTTHOST" -t "$MQTTTOPIC/$VIN/set/#" $EXTRAS -v | while read -r topic payload
    do
        echo "Rx: ${topic}: ${payload}"
        if [[ "$topic" == "$MQTTTOPIC/$VIN/set/climate" ]]
        then
            ./leaf_climate.exe --username=$USERNAME --password=$PASSWORD --temperature "${payload}"
        # elif [[ "$topic" == "$MQTTTOPIC/$VIN/set/charge" ]]
        # then
        #     ./leaf_charge.exe --username=$USERNAME --password=$PASSWORD --operation "${payload}"
        fi
        ./leaf2mqtt-once.sh
    done
done

