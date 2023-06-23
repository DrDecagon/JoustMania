#!/bin/bash

if [ $UID -ne 0 ]; then
  echo "Not root. Using sudo."
  exec sudo $0
fi

echo "Setting CPU performance mode on all cores"
echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo "Setting max temp"
echo 70000 | tee /sys/class/thermal/thermal_zone0/trip_point_0_temp

#supervisord does not have a login name
#so we need to find the JoustMania install directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

export HOME="/root"
export PYTHONPATH=$(dirname $SCRIPT_DIR)"/psmoveapi/build/"
exec $SCRIPT_DIR/venv/bin/python3 $SCRIPT_DIR/piparty.py
