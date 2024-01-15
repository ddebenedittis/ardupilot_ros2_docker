#!/bin/bash
set -e

# ArduPilot
source $HOME/.ardupilot_env

# Setup environment
source $HOME/.bashrc

# Change owner of file
chown $USER /home/.bash_history

# Start in home directory
