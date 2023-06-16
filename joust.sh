#!/bin/bash

if [ $UID -ne 0 ]; then
  echo "Not root. Using sudo."
  exec sudo $0
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#supervisord does not have a login name
#so we need to find the JoustMania install directory

export HOME="/root"
export PYTHONPATH=$(dirname $SCRIPT_DIR)"/psmoveapi/build/"
exec $SCRIPT_DIR/venv/bin/python3 $SCRIPT_DIR/piparty.py
