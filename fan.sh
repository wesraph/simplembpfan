#!/bin/sh

DEBUG=0

TEMP="/sys/devices/platform/applesmc.768/"
FAN="/sys/devices/platform/applesmc.768/fan1"

FAN_MAX="$(cat "$FAN"_max)"
FAN_MIN="$(cat "$FAN"_min)"

DRY_RUN=0

T_MIN=62
T_HIGH=71
T_MAX=80

STEP_UP="$(echo "($FAN_MAX - $FAN_MIN) / (($T_MAX - $T_HIGH) * ($T_MAX - $T_HIGH + 1) / 2)" | bc -l)"

STEP_DOWN="$(echo "($FAN_MAX - $FAN_MIN) / (($T_MAX - $T_MIN) * ($T_MAX - $T_MIN + 1) / 2)" | bc -l)"

_debug() {
	if [ "$DEBUG" -eq "1" ]; then
		echo "$1"
	fi
}

_get_max_temp() {
    echo "$(cat $TEMP/temp*_input | grep -v "-" | sort -r | head -n 1)" / 1000 | bc
}

_get_fan_speed() {
    cat "$FAN"_input
}

_set_fan_speed() {
    if [ "$DRY_RUN" = 0 ]; then
        _round "$1" > "$FAN"_output
    fi
}

_round() {
    echo "$1" / 1 | bc
}

_max() {
    if [ "$(_round "$1")" -gt "$(_round "$2")" ]; then
        echo "$1"
    else
        echo "$2"
    fi
}

_min() {
    if [ "$(_round "$1")" -lt "$(_round "$2")" ]; then
        echo "$1"
    else
        echo "$2"
    fi
}

_debug "Setting fan in manual mode"
echo 1 > "$FAN"_manual

oldTemp="$(_get_max_temp)"

while :
do
    actualTemp="$(_get_max_temp)"
    actualFan="$(_get_fan_speed)"

    if [ "$actualTemp" -ge "$T_MAX" ] && [ "$actualFan" -lt "$FAN_MAX" ]; then
        _debug "Setting max speed"
        _set_fan_speed "$FAN_MAX"
    fi

    if [ "$actualTemp" -le "$T_MIN" ] && [ "$actualFan" != "$FAN_MIN" ]; then
        _debug "Setting min speed"
        _set_fan_speed "$FAN_MIN"
    fi

    delta="$(echo "$actualTemp" - "$oldTemp" | bc)"

    if [ "$delta" -gt 0 ] && [ "$actualTemp" -gt "$T_HIGH" ] && [ "$actualTemp" -lt "$T_MAX" ]; then
        step="$(echo "($actualTemp - $T_HIGH) * ($actualTemp - $T_HIGH + 1) / 2" | bc -l)"
        _debug "Stepping up"
        _set_fan_speed "$(_max "$actualFan" "$(echo "$FAN_MIN + $step * $STEP_UP" | bc)" )"
    fi

    if [ "$delta" -lt 0 ] && [ "$actualTemp" -gt "$T_MIN" ] && [ "$actualTemp" -lt "$T_MAX" ]; then
        step="$(echo "($T_MAX - $actualTemp) * ($T_MAX - $actualTemp + 1) / 2" | bc -l)"
        echo "Stepping down"
        _set_fan_speed "$(_min "$actualFan" "$(echo "$FAN_MAX - $step * $STEP_DOWN" | bc)" )"
    fi

    _debug "Temp: $actualTemp, Fan speed: $actualFan, Delta: $delta"

    oldTemp="$actualTemp"

    sleep 1
done
