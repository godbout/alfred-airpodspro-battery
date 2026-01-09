#!/bin/zsh

function print_device() {
    if [ "$device" != "" ]; then
        CASE_BATTERY_LEVEL=$(echo "${device}" | awk '/Case Battery Level/{print $4}')
        LEFT_BATTERY_LEVEL=$(echo "${device}" | awk '/Left Battery Level/{print $4}')
        RIGHT_BATTERY_LEVEL=$(echo "${device}" | awk '/Right Battery Level/{print $4}')
        battery="${result_title/CASE_BATTERY_LEVEL/$CASE_BATTERY_LEVEL}"
        battery="${battery/LEFT_BATTERY_LEVEL/$LEFT_BATTERY_LEVEL}"
        battery="${battery/RIGHT_BATTERY_LEVEL/$RIGHT_BATTERY_LEVEL}"

        if [[ "$LEFT_BATTERY_LEVEL" = "" && "$RIGHT_BATTERY_LEVEL" = ""  ]]; then
            battery=$(echo "${device}" | awk '/Battery Level/{print $3}')
        fi

        if [[ "$battery" != "" ]]; then
            echo "<item> <title>$battery</title> <subtitle>$name</subtitle> </item>"
        fi
    fi
}

WHOLE_BLUETOOTH_DATA=$(system_profiler SPBluetoothDataType 2>/dev/null)
CONNECTED_HEADPHONES=$(awk '/  Connected:/{f=1;next} /Not Connected:/{f=0} f' <<< "${WHOLE_BLUETOOTH_DATA}" | grep -B4 "Battery Level:")
APPLE_CONNECTED_HEADPHONES_COUNT=$(echo $CONNECTED_HEADPHONES | grep -c "Vendor ID: 0x004C")

if [[ "$APPLE_CONNECTED_HEADPHONES_COUNT" != "0"  ]]; then
    echo "<?xml version='1.0' encoding='utf-8'?> <items>" # use XML as it will be easier to print logs to the output into alfred with echo

    nl=$'\n'
    name=""
    device=""

    CONNECTED_HEADPHONES="$CONNECTED_HEADPHONES$nl--" # append a separator to the end

    ## split CONNECTED into devices
    echo "${CONNECTED_HEADPHONES}" | while read -r line
    do
        if [ "$device" = "" ]
            then
            name=${line%?} # remove the colon: at the last place of device name
            device="$line"
        elif [ "$line" = "--" ]
            then
            print_device # print device battery in XML
            device=""
        else
            echo $line
            device="$device$nl$line" # append more lines to the device
        fi
    done

    echo "</items>"
else
cat << EOB
    {"items": [
        {
            "uid": "battery",
            "title": "not connected",
        }
    ]}
EOB
fi
