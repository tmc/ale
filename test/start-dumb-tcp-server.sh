#!/usr/bin/env bash

# This script is a wrapper script for starting the dump Python TCP server in
# the background and returning the process ID and port for it.

# Change directory to where the script is.
cd "$(dirname "$(realpath "$0")")"

set -eu

port=10347

python dumb_tcp_server.py "$port" &
pid=$!

echo "$pid" "$port"
