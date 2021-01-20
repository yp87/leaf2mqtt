#!/bin/bash

cd /root
while true
do
    echo "#!/bin/bash" > cmd.sh
    if [ -z "$MQTTUSER" ]
    then
        dart leaf2mqtt.dart --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC > cmd.sh
    else
        dart leaf2mqtt.dart --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC --mqttuser=$MQTTUSER --mqttpass=$MQTTPASS > cmd.sh
    fi
    chmod +x cmd.sh
    ./cmd.sh
    if grep --quiet "/connected\" -m \"true\"" cmd.sh; then
        if grep --quiet "/charging\" -m \"true\"" cmd.sh; then
            sleep 300
        else
            sleep 600
        fi
    else
        sleep 1800
    fi
done
