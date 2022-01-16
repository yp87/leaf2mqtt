![Docker Pulls](https://img.shields.io/docker/pulls/yp87/leaf2mqtt) ![Docker Image Version (latest by date)](https://img.shields.io/docker/v/yp87/leaf2mqtt)
# leaf2mqtt
> :warning: If you're not using the Leaf frequently, stop the container or drastically reduce the update frequency, or you could well end up with a flat 12V battery.

This works for my Canadian made in 2018 LEAF 40kWh. It was also reported to be working on a newer than May 2019 Leaf.

You must have a working MQTT broker on your LAN.

Should work with multiple Leafs, but it is untested. Please open an issue with feedback if possible.

- [Setup](#setup)
  * [Pre-built images](#pre-built-images-)
  * [Building the image](#building-the-image-)
  * [Running the image](#running-the-image-)
- [Status and Commands](#status-and-commands)
  * [General](#general)
    + [Status](#status)
    + [Commands](#commands)
  * [Battery](#battery)
    + [Status](#status-1)
    + [Commands](#commands-1)
  * [Climate](#climate)
    + [Status](#status-2)
    + [Commands](#commands-2)
  * [Stats](#stats)
    + [Status](#status-3)
    + [Commands](#commands-3)
  * [Location](#location)
    + [Status](#status-4)
    + [Commands](#commands-4)
- [Home Assistant Integration](#home-assistant-integration)
  * [Sensor examples](#sensor-examples)
  * [Recommended Battery Status Update Script](#recommended-battery-status-update-script)
- [Credits](#credits)

## Setup
### Pre-built images
You can use pre-built images from here: https://hub.docker.com/r/yp87/leaf2mqtt

tag example: `yp87/leaf2mqtt:latest`

### Building the image

    docker build --tag leaf2mqtt .

         -- OR --

    cp local_settings.env.tmpl local_settings.env
    docker-compose build

### Running the image
| Parameter | Optional | Description |
|-----------|----------|-------------|
| LEAF_USERNAME | No | Your NissanConnect username ||
| LEAF_PASSWORD | No | Your NissanConnect password |
| LEAF_TYPE | No | newerThanMay2019, olderCanada, olderUSA, olderEurope, olderAustralia or olderJapan |
| MQTT_HOST | No | IP or hostname of your mqtt broker. Localhost or 127.0.0.1 will not work when using Docker, use real host LAN ip |
| MQTT_PORT | Yes | Port of your mqtt broker. Default is 1883  |
| MQTT_USERNAME | Yes | Your mqtt username |
| MQTT_PASSWORD | Yes | Your mqtt password |
| MQTT_BASE_TOPIC | Yes | The root MQTT topic for leaf2mqtt. Default is "leaf" |
| UPDATE_INTERVAL_MINUTES | Yes | Time between automatic status refresh. Default is 60 |
| CHARGING_UPDATE_INTERVAL_MINUTES* | Yes | Time between automatic status refresh when charging. Default is 15 |
| COMMAND_ATTEMPTS | Yes | Number of attempts for any command regardless of success or failure. Since some of the Nissan apis are unreliable, I recommend a value of 5. Default is 1. |
| LOG_LEVEL | Yes | The log verbosity used by leaf2mqtt. Default is "Warning" |

Example:

    docker run --restart always -e LEAF_USERNAME="myusername@somewhere.com" -e LEAF_PASSWORD="Some P4ssword!" -e LEAF_TYPE="newerThanMay2019" -e MQTT_HOST=192.168.1.111 -e UPDATE_INTERVAL_MINUTES=1440 -e COMMAND_ATTEMPTS=5 --name leaf2mqtt leaf2mqtt

         -- OR --

    Edit local_settings.env
    docker-compose up -d

:information_source:* The `CHARGING_UPDATE_INTERVAL_MINUTES` value will only be used after the ongoing `UPDATE_INTERVAL_MINUTES` is elapsed and the Leaf is charging.

## Status and Commands
In these examples, the `MQTT_BASE_TOPIC` is set to the default (`leaf`).

### General
#### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/nickname | String | The reported nickname of the leaf  |
| leaf/{vin}/vin  | String | The reported vin of the leaf  |
| leaf/{vin}/lastErrorDateTimeUtc  | Iso8601 UTC | The datetime of the last failed command execution or status query |
| leaf/{vin}/json | String | A json representation of all general status |

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
| leaf/{vin}/battery/json | String | A json representation of all battery status |

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
| leaf/{vin}/climate/json | String | A json representation of all climate status |

#### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/climate | update | Request an update for all climate status |
| leaf/{vin}/command/climate | start | Request the Leaf to start climate control |
| leaf/{vin}/command/climate | startC XY | Request the Leaf to start climate control at XY Celsius |
| leaf/{vin}/command/climate | startF XY | Request the Leaf to start climate control at XY Fahrenheit |
| leaf/{vin}/command/climate | stop | Request the Leaf to stop climate control |

### Stats
`{TimeRange}` must be `daily` or `monthly`.

#### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/stats/{TimeRange}/targetDate | Iso8601 | The reported target date of the stats |
| leaf/{vin}/stats/{TimeRange}/travelTimeHours | double | The reported time traveled in hours during specified time range |
| leaf/{vin}/stats/{TimeRange}/travelDistanceMiles | double | The reported miles traveled during specified time range |
| leaf/{vin}/stats/{TimeRange}/travelDistanceKilometers | double | The reported kilometers traveled during specified time range |
| leaf/{vin}/stats/{TimeRange}/milesPerKwh | double | The reported miles per kWh during specified time range |
| leaf/{vin}/stats/{TimeRange}/kilometersPerKwh | double | The reported kilometers per kWh during specified time range |
| leaf/{vin}/stats/{TimeRange}/kwhUsed | double | The reported kWh consumption during specified time range |
| leaf/{vin}/stats/{TimeRange}/kwhPerMiles | double | The reported kWh consumption per miles during specified time range |
| leaf/{vin}/stats/{TimeRange}/kwhPerKilometers | double | The reported kWh consumption per km during specified time range |
| leaf/{vin}/stats/{TimeRange}/co2ReductionKg | double | The reported number of co2 in Kg saved during specified time range |
| leaf/{vin}/stats/{TimeRange}/tripsNumber | int | The reported number of trips during specified time range |
| leaf/{vin}/stats/{TimeRange}/kwhGained | Double | The reported total regen in kWh during specified time range |
| leaf/{vin}/stats/{TimeRange}/lastReceivedDateTimeUtc | Iso8601 UTC | The datetime when leaf2mqtt received the last stats values |
| leaf/{vin}/stats/json | String | A json representation of all stats |

#### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/stats/{TimeRange} | update YYYY-MM-DD HH:MM:SS | Request an update for daily or monthly stats. Date must respect Iso8601 |

### Location
#### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/location/latitude | String | The reported last known location's latitude in decimal degrees |
| leaf/{vin}/location/longitude | String | The reported last known location's longitude in decimal degrees |
| leaf/{vin}/location/lastReceivedDateTimeUtc | Iso8601 UTC | The datetime when leaf2mqtt received the last location values |
| leaf/{vin}/location/json | String | A json representation of all location status |

#### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/location | update | Request an update for the last known location |

:information_source: The status and commands for the first Leaf in the account are also supported by using the same topic without the {vin}.

:warning: Not all status and commands are supported for a given leaf type due to Carwings, NissanConnectNA or NissanConnect api limitations.

## Home Assistant Integration
### Sensor examples
    sensors:
      - platform: mqtt
        name: leaf_battery_level
        # Since VIN is not specified, it will represent the state from the first vehicle in the account.
        state_topic: "leaf/battery/percentage"
        unit_of_measurement: "%"
        device_class: battery

      - platform: mqtt
        name: leaf_battery_last_updated
        # Since VIN is not specified, it will represent the state from the first Leaf in the account.
        state_topic: "leaf/battery/lastUpdatedDateTimeUtc"
        device_class: timestamp

      - platform: mqtt
        name: leaf_battery_last_received
        # You can specify the vin if you prefer or if you have more than one Leaf.
        state_topic: "leaf/XXXXXSOMEXVINXXXXX/battery/lastReceivedDateTimeUtc"
        device_class: timestamp

### Recommended Battery Status Update Script
In Home Assistant, calling a script like this `- service: script.some_script_name` within another script or automation will actually stop the execution of the calling script until `script.some_script_name` terminates, unlike using `script.turn_on`. Knowing this, you can ensure you have the latest state for your leaf before continuing an automation using a script like this:

    update_leaf_battery:
      # Using queued will ensure you do not update twice at the same time and will prevent
      # subsequent invocations from asking an update right away because of the while's conditions.
      # All the callers will also wait for the result.
      mode: queued
      sequence:
        - repeat:
            while:
              # Used with the sensors in the section above, this condition will
              # ensure we continue until the states are really updated.
              # It will also prevent subsequent calls from unnecessarily requesting
              # an update before the current state is 10 minutes old.
              - >
                {{ as_timestamp(now()) -
                  as_timestamp(states('sensor.leaf_battery_last_updated')) > 600 }}

              # We also stop the loop after 4 tries since Nissan servers can send the same
              # old data many times in a row. I think this happens when the state did not really changed
              # or the Leaf is unreachable. 
              - "{{ repeat.index <= 4 }}"

            sequence:
              # We publish the update command for the car. 
              # You can also ommit the VIN to target the first Leaf in the account.
              # You can also request update for every state for one Leaf by removing the /battery section
              - service: mqtt.publish
                data:
                  topic: "leaf/XXXXXSOMEXVINXXXXX/command/battery"
                  payload: "update"
              # We now wait until we actually have received a response or if we timed out.
              # This does not mean that the received data is the latest. This is why
              # we check sensor.leaf_battery_last_updated in the while condition.
              - wait_for_trigger:
                  - platform: state
                    entity_id: sensor.leaf_battery_last_received
                timeout: 600
        # Let's have a cool down to give time to Home Assistant to update all the states.
        - delay: "00:00:10"

## Credits
- Forked from [Troon/leaf2mqtt](https://github.com/Troon/leaf2mqtt). Thank you for the inspiration!
- Using libraries from [Tobias Westergaard Kjeldsen](https://gitlab.com/tobiaswkjeldsen) to connect with the nissan leaf's APIs. Those libraries are also used for his [MyLeaf app](https://gitlab.com/tobiaswkjeldsen/carwingsflutter).
