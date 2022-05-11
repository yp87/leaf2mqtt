#!/usr/bin/env bashio

bashio::log.blue \
        '---------------------------------------------------'
bashio::log.blue \
        '-                    LEAF2MQTT                    -'
bashio::log.blue \
        '---------------------------------------------------'


bashio::log.green "Setting environment variables..."

for k in $(bashio::jq "${__BASHIO_ADDON_CONFIG}" 'keys | .[]'); do
    export $k="$(bashio::config $k)"
done

echo "Done."


bashio::log.green "Starting leaf2mqtt..."

/app/bin/leaf_2_mqtt
