# leaf2mqtt
Builds a Docker container to pull in data from the Nissan Connect platform for the LEAF and publish over MQTT, using Tobias Westergaard Kjeldsen's excellent `dartnissanconnect` library which is also the basis for the MyLeaf app. Climate on/off control is available, but beware that it is slow and unreliable.

This works for my UK-based 2020 LEAF 40kWh car, and *should* work for any European LEAF that uses the NissanConnect app ([Android](https://play.google.com/store/apps/details?id=eu.nissan.nissanconnect.services&hl=en_GB&gl=US) or [iOS](https://apps.apple.com/gb/app/nissanconnect-services/id1451280347)). Please ensure you have installed the app and can communicate with the car before proceeding with this.

This **will not** work for older "original-shape" LEAFs. Don't waste any time trying.

You must have a working MQTT server on your LAN. The container uses `mosquitto` for publishing its data. I use this for interfacing with Home Assistant (running on a Synology NAS, hence the Docker container approach) via MQTT sensors: see `leaf-sensors.yaml`, `leaf-binary-sensors.yaml` and `leaf-switches.yaml` for examples (and replace the MY_VIN with your VIN from the MQTT messages once you have the steps below working!).

You must also have a working Docker installation, and be comfortable building images and running them as containers. Should work fine for `x86_64` architectures; others may need a little work, particularly for the `dart` installation step.

Please note that I created this for my own personal use and am not looking for feedback, issues, feature requests etc. It's provided here as a starting point for your own projects.

## Instructions

1. Create a folder e.g. `leaf2mqtt`
1. Drop all these files into that folder (Code button, Download ZIP).
1. `cd` into that folder
1. Run `./image-build.sh`, which will prompt you for your `sudo` password
1. That should have created a `leaf2mqtt` image: now you need to fire up a container from it. Doesn't need filesystem access, but you need to set four or six environment variables:
    1. `MQTTTOPIC`: I set this to `leaf` and you should too unless you have a good reason not to
    1. `MQTTHOST`: LAN IP address of your MQTT broker.
    1. `USERNAME`: your NissanConnect username — the one you use to log into the app.
    1. `PASSWORD`: your NissanConnect password — the one you use to log into the app.
    1. `MQTTUSER`: (optional) Username for your MQTT broker.
    1. `MQTTPASS`: (optional) Password for your MQTT broker.

If all goes well, you should start to see the messages coming through on MQTT. By default, the refresh frequency is once every 30 minutes, increasing to every 10 minutes if connected and not charging, and every 5 minutes if charging. There is also a "one-shot" update after setting the climate. These times can be changed at the end of `leaf2mqtt.sh` prior to building the Docker image if needed, but don't set the times too low or you may get blocked from Nissan's servers.
