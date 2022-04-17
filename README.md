# :red_car::maple_leaf: leaf2mqtt :maple_leaf::red_car:
leaf2mqtt takes data from Nissan Leaf connected vehicles - usually consumed via a mobile app, into MQTT based pub/sub messaging for integrating into other applications / home automation solutions. 

> :warning: Be aware that long term polling from this container against your Leaf without regular (weekly) usage / charging could drain your 12V battery. 

This module has been reported to work on the following Leaf models:
- :red_car: 2018+ Leaf 40kWh from Canada
- :red_car: 2018+ Leaf 62 kWh e+ from UK

For this to work with other applications / Home Automation systems - an MQTT broker is required to interconnect. leaf2mqtt operates as an MQTT client.  

This should work with multiple Leafs, has only been briefly tested. Please open an issue with feedback if you encounter issues. 

### Overview
- :rocket: [Setup](#setup)
- :memo: [Status and Commands](#status-and-commands)
- :house: [Home Assistant integration](#home-assistant-integration)
- :handshake: [Credits](#credits)

## :rocket: Setup
#### Running leaf2mqtt
leaf2mqtt is packaged as a container. This is an automatically published / updated at the [k8s-at-home](https://github.com/k8s-at-home/container-images/pkgs/container/leaf2mqtt) container registry. This can be used immediately without any building required. 

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

##### Example:
```
docker run --restart always -e LEAF_USERNAME="myusername@somewhere.com" -e LEAF_PASSWORD="Some P4ssword!" -e LEAF_TYPE="newerThanMay2019" -e MQTT_HOST=192.168.1.111 -e UPDATE_INTERVAL_MINUTES=1440 -e COMMAND_ATTEMPTS=5 --name leaf2mqtt ghcr.io/k8s-at-home/leaf2mqtt:latest
```

:information_source: The `CHARGING_UPDATE_INTERVAL_MINUTES` value will only be used after the ongoing `UPDATE_INTERVAL_MINUTES` is elapsed and the Leaf is charging.

#### :boat: Helm Chart
There is a helm chart available for leaf2mqtt available at [k8s-at-home](https://github.com/k8s-at-home/charts/tree/master/charts/stable/leaf2mqtt)

## :memo: Status and Commands
In these examples, the `MQTT_BASE_TOPIC` is set to the default (`leaf`). 

#### :red_car: General
##### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/nickname | String | The reported nickname of the leaf  |
| leaf/{vin}/vin  | String | The reported vin of the leaf  |
| leaf/{vin}/lastErrorDateTimeUtc  | Iso8601 UTC | The datetime of the last failed command execution or status query |
| leaf/{vin}/json | String | A json representation of all general status |

##### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command | update | Request an update for all status  |


#### :battery: Battery
##### Status
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

##### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/battery | update | Request an update for all battery status  |
| leaf/{vin}/command/battery | startCharging | Request the Leaf to start charging  |

#### :snowflake: Climate
##### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/climate/cabinTemperatureC | Double | The reported cabin temperature in Celsius |
| leaf/{vin}/climate/cabinTemperatureF | Double | The reported cabin temperature in Fahrenheit |
| leaf/{vin}/climate/runningStatus | Boolean | True if the Leaf is reporting the HVAC as running. False otherwise |
| leaf/{vin}/climate/lastReceivedDateTimeUtc | Iso8601 UTC | The datetime when leaf2mqtt received the last climate values |
| leaf/{vin}/climate/json | String | A json representation of all climate status |

##### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/climate | update | Request an update for all climate status |
| leaf/{vin}/command/climate | start | Request the Leaf to start climate control |
| leaf/{vin}/command/climate | startC XY | Request the Leaf to start climate control at XY Celsius |
| leaf/{vin}/command/climate | startF XY | Request the Leaf to start climate control at XY Fahrenheit |
| leaf/{vin}/command/climate | stop | Request the Leaf to stop climate control |

#### :satellite: Location
##### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/location/latitude | String | The reported latitude |
| leaf/{vin}/location/longitude | String | The reported longitude |
| leaf/{vin}/location/location | String | JSON formatted location for Home-Assistant |

##### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/location | update | Request an update for location |

#### :calendar: Stats
`{TimeRange}` must be `daily` or `monthly`.

##### Status
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

### Cockpit Status
#### Status
| Topic  | Type | Description |
| ------ | ---- | ----------- |
| leaf/{vin}/cockpitStatus/totalMileage | Double | The total mileage from the vehicle. The unit (km or miles) depends on the regional area. |

##### Commands
| Topic | Payload | Description |
| ----- | ------- | ----------- |
| leaf/{vin}/command/cockpitStatus | update | Request an update for the cockpit status |

:information_source: The status and commands for the first Leaf in the account are also supported by using the same topic without the {vin}.

:warning: Not all status and commands are supported for a given leaf type due to Carwings, NissanConnectNA or NissanConnect api limitations.

### :house: Home Assistant Integration
#### Sensor examples
```
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
```

#### Recommended Battery Status Update Script
In Home Assistant, calling a script like this `- service: script.some_script_name` within another script or automation will actually stop the execution of the calling script until `script.some_script_name` terminates, unlike using `script.turn_on`. Knowing this, you can ensure you have the latest state for your leaf before continuing an automation using a script like this:
```
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
```

#### Home-Assistant Climate Integration
It's possible to build a climate based control for the Leaf in Home-Assistant. This allows you to use the standard climate controls rather that building separate sensors / input switches. 

:information_source: The sensor is required to capture the temperature set for the `mode_command_topic`
```
sensor:
  - platform: mqtt
    name: "LEAF Target Temp"
    state_topic: "leaf/XXXXXSOMEXVINXXXXX/climate/climateTargetTempC"
    device_class: temperature
    unit_of_measurement: "C"

climate: 
  - platform: mqtt
    name: "Leaf Climate"
    modes: 
      - "auto"
      - "off"
    mode_command_topic: "leaf/XXXXXSOMEXVINXXXXX/command/climate"
    mode_command_template: "{{'startC ' + states('sensor.leaf_target_temp') | round() | string() if value == 'auto' else 'stop'}}"
    mode_state_topic: "leaf/XXXXXSOMEXVINXXXXX/climate/RunningStatus"
    mode_state_template: "{{'auto' if value == 'true' else 'off'}}"
    current_temperature_topic: "leaf/XXXXXSOMEXVINXXXXX/climate/cabinTemperatureC"
    temperature_state_topic: "leaf/XXXXXSOMEXVINXXXXX/climate/climateTargetTempC"
    min_temp: 16
    max_temp: 26
    precision: 1.0
    temperature_command_topic: "leaf/XXXXXSOMEXVINXXXXX/climate/climateTargetTempC"
```

#### Home-Assistant Location Integration
You can add your Leaf as a `device_tracker` type in Home-Assistant. This allows you to track in a similar way to phones / people, and easily display location updates on a map. 

```
device_tracker:
  - platform: mqtt_json
    devices:
      Leaf: leaf/XXXXSOMEXVINXXXXX/location/json
```

### :handshake: Credits
- Forked from [yp87/leaf2mqtt](https://github.com/yp87/leaf2mqtt). Thanks for a great basis on which to enhance. 
- Using libraries from [Tobias Westergaard Kjeldsen](https://gitlab.com/tobiaswkjeldsen) to connect with the nissan leaf's APIs. Those libraries are also used for his [MyLeaf app](https://gitlab.com/tobiaswkjeldsen/carwingsflutter).
