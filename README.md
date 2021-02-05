# leaf2mqtt

**Unstable. This is a work in progress.**

> :warning: If you're not using the Leaf frequently, stop the container or drastically reduce the update frequency, or you could well end up with a flat 12V battery.

This works for my Canadian made in 2018 LEAF 40kWh car. Please open an issue if it also works for your different model and/or region, I will then update this list.

You must have a working MQTT broker on your LAN.

Should work with multiple Leafs, but it is untested. Please open an issue with feedback if possible.

More documentation will follow.

Building the image:

    docker build -tag leaf2mqtt .

Running the image:

    docker run -e LEAF_USERNAME=[Your NissanConnect username] -e LEAF_PASSWORD="[Your NissanConnect password]" -e LEAF_TYPE=[newerThanMay2019, olderCanada or olderUSA] -e MQTT_USERNAME="[Optional. Your mqtt username]" -e MQTT_PASSWORD="[Optional. Your mqtt password]" -e MQTT_HOST=[IP or hostname of your mqtt broker] -e MQTT_BASE_TOPIC=[Optional. Default = leaf] --name leaf2mqtt leaf2mqtt

MQTT topics using the default `MQTT_BASE_TOPIC` (`leaf`):    

## Status and Commands

### General
#### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/nickname | String | The reported nickname of the leaf  |
| leaf/{vin}/vin  | String | The reported vin of the leaf  |

#### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command | update | Request an update for all status  |


### Battery
#### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/battery/percentage | Integer | The last reported battery charge of the leaf |
| leaf/{vin}/battery/connected| Boolean | True if the leaf is reported as currently connected. False otherwise |
| leaf/{vin}/battery/charging| Boolean | True if the leaf is reported as currently charging. False otherwise |
| leaf/{vin}/battery/capacity| Double | The reported total capacity of the battery |
| leaf/{vin}/battery/chargingSpeed| String | can be one of None, Slow, Normal or Fast  |
| leaf/{vin}/battery/cruisingRangeAcOffKm | Integer | Range left with climate off in kilometers as estimated by the Leaf |
| leaf/{vin}/battery/cruisingRangeAcOffMiles | Integer | Range left with climate off in miles as estimated by the Leaf |
| leaf/{vin}/battery/cruisingRangeAcOnKm | Integer | Range left with climate on in kilometers as estimated by the Leaf |
| leaf/{vin}/battery/cruisingRangeAcOnMiles | Integer | Range left with climate on in miles as estimated by the Leaf |
| leaf/{vin}/battery/timeToFullTrickleInMinutes | Integer | The reported time in minutes to fully charge when trickling (~1kw) |
| leaf/{vin}/battery/timeToFullL2InMinutes | Integer | The reported time in minutes to fully charge when charging in half speed L2 (~3kw) |
| leaf/{vin}/battery/timeToFullL2_6kwInMinutes | Integer | The reported time in minutes to fully charge when charging in full speed L2 (~6kw) |
| leaf/{vin}/battery/lastUpdatedDateTimeUtc | Iso8601 UTC | The datetime when the last battery values were updated |
| leaf/{vin}/battery/lastReceivedDateTimeUtc | Iso8601 UTC | The datetime when leaf2mqtt received the last battery values |

#### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/battery | update | Request an update for all battery status  |
| leaf/{vin}/command/battery | startCharging | Request the Leaf to start charging  |

### Climate
#### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/climate/cabinTemperatureC | Double | The reported cabin temperature in Celsius |
| leaf/{vin}/climate/cabinTemperatureF | Double | The reported cabin temperature in Fahrenheit |
| leaf/{vin}/climate/runningStatus | Boolean | True if the Leaf is reporting the HVAC as running. False otherwise |
| leaf/{vin}/climate/lastReceivedDateTimeUtc | Iso8601 UTC | The datetime when leaf2mqtt received the last climate values |

#### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/climate | update | Request an update for all climate status |
| leaf/{vin}/command/climate | start | Request the Leaf to start climate control |
| leaf/{vin}/command/climate | startC XY | Request the Leaf to start climate control at XY Celsius |
| leaf/{vin}/command/climate | startF XY | Request the Leaf to start climate control at XY Fahrenheit |
| leaf/{vin}/command/climate | stop | Request the Leaf to stop climate control |

:information_source: The status and commands for the first Leaf in the account are also supported by using the same topic without the {vin}.

:warning: Not all status and commands are supported for a given leaf type due to Carwings, NissanConnectNA or NissanConnect api limitations.

## Credits
- Forked from [Troon/leaf2mqtt](https://github.com/Troon/leaf2mqtt). Thank you for the inspiration!
- Using libraries from [Tobias Westergaard Kjeldsen](https://gitlab.com/tobiaswkjeldsen) to connect with the nissan leaf's APIs. Those libraries are also used for his [MyLeaf app](https://gitlab.com/tobiaswkjeldsen/carwingsflutter).
