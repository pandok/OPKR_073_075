#!/usr/bin/bash

# Adapted from Erich's tri-state switch mod which allows choosing from three installed openpilot locations on boot
# I've only really added some error-checking and fallback options
# Boot locations:
#  /data/openpilot.1
#  /data/openpilot.2
#  /data/openpilot.3
#
# Moves existing real /data/openpilot dir (I.E not a symlink) to /data/openpilot.backup
# Tries to boot the remaining locations if the first choice doesn't exist
# Preserves LiveParameters and kegman.json for each boot location

# Turn on WiFi hotspot on boot
# Want to add (probably need to make separate script, actually):
#  -Wait 60 sec on boot and cancel if WiFi is already connected to something
#  -Turn off hotspot if not 'driving' for 5 minutes (maybe watch if controlsd is running)
#
# service call wifi 37 i32 0 i32 [X]  # X: 1=on, 2=off
# service call wifi 37 i32 0 i32 1

switchstate=`cat /sys/devices/virtual/switch/tri-state-key/state` || switchstate=5
echo $switchstate

if [ -L "/data/openpilot" ]; then
  switchstate_old=`ls -ltr /data/openpilot|tail -c 2`
  echo $switchstate_old
  if ! (( 0 < $switchstate_old && $switchstate_old < 4 )); then
    switchstate_old=6
  fi
  else
    switchstate_old=6
fi

#echo $switchstate_old

# Check there's a switchstate between 1-3 and that the switch is in a new position before doing anything
if (( 0 < $switchstate && $switchstate < 4 && $switchstate_old != $switchstate )); then

  # Check to see the target dir exists
  if [ -d "/data/openpilot.$switchstate" ]; then
    cp /data/params/d/LiveParameters /data/LiveParameters.$switchstate_old
    cp /data/kegman.json /data/kegman.json.$switchstate_old

    if [ -L "/data/openpilot" ]; then
      rm -r /data/openpilot
    else
      # If not a symlink, make a backup, just in case there's something in /data/openpilot we care about
      rm -rf /data/openpilot.backup
      mv /data/openpilot /data/openpilot.backup
    fi

    rm -f /data/params/d/LiveParameters
    rm -f /data/kegman.json               # Erich isn't doing this for some reason
    ln -fs /data/openpilot.$switchstate /data/openpilot
    cp /data/LiveParameters.$switchstate /data/params/d/LiveParameters
    cp /data/kegman.json.$switchstate /data/kegman.json
  fi

fi

# If no OP dir, try other options
cd /data/openpilot || ln -fs /data/openpilot.$switchstate /data/openpilot || \
  ln -fs /data/openpilot.1 /data/openpilot || \
  ln -fs /data/openpilot.2 /data/openpilot || \
  ln -fs /data/openpilot.3 /data/openpilot || \
  ln -fs /data/openpilot.backup /data/openpilot

cd /data/openpilot
exec ./launch_openpilot.sh