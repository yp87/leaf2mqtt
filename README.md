# leaf2mqtt
Pull in data from the Nissan Connect platform for the LEAF and publish over MQTT. This works for my UK-based 2020 LEAF 40kWh car, and *should* work for any European LEAF that uses the NissanConnect app. Please ensure you have installed the app and can communicate with the car before proceeding with this.

You must have a working MQTT server on your LAN that is not password-protected. I use this for interfacing with Home Assistant via MQTT sensors: see `leaf.yaml` for examples.

Please note that I created this for my own personal use and am not looking for feedback, issues, feature requests etc. It's provided here as a starting point for your own projects.

Uses Tobias Westergaard Kjeldsen's excellent `dartnissanconnect` library.

