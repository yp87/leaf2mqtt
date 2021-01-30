# leaf2mqtt

**This is a work in progress.**

> :warning: If you're not using the car frequently, stop the container or drastically reduce the update frequency, or you could well end up with a flat 12V battery.

* Support for other regions is planned.

This works for my Canadian 2019 LEAF 40kWh car. Please open an issue if it also works for your different model and/or region, I will update this list.

You must have a working MQTT broker on your LAN.

More documentation will follow.

Building the image:

    docker build -tag leaf2mqtt .

Running the image:

    docker run -e LEAF_USERNAME=[Your NissanConnect username] -e LEAF_PASSWORD="[Your NissanConnect password]" -e LEAF_REGION="[CA or US]" -e MQTT_USERNAME="[Optional. Your mqtt username]" -e MQTT_PASSWORD="[Optional. Your mqtt password]" -e MQTT_HOST=[IP or hostname of your mqtt broker] -e MQTT_BASE_TOPIC=[Optional. Default = leaf] --name leaf2mqtt leaf2mqtt

MQTT topics using the default `MQTT_BASE_TOPIC` (`leaf`):    

    leaf/nickname           # [String] The reported nickname of the leaf
    leaf/vin                # [String] The reported vin of the leaf

    leaf/battery/percentage # [Integer 0 to 100] The last reported battery charge of the leaf
    leaf/battery/connected  # [Boolean] True if the leaf is reported as currently connected. False otherwise
    leaf/battery/charging   # [Boolean] True if the leaf is reported as currently charging. False otherwise
    leaf/battery/updated    # [Iso8601 UTC] The datetime when leaf2mqtt received the last battery values

## Credits
- Forked from [Troon/leaf2mqtt](https://github.com/Troon/leaf2mqtt). Thank you for the inspiration!
- Using libraries from [Tobias Westergaard Kjeldsen](https://gitlab.com/tobiaswkjeldsen) to connect with the nissan leaf's APIs. Those libraries are also used for his [MyLeaf app](https://gitlab.com/tobiaswkjeldsen/carwingsflutter).