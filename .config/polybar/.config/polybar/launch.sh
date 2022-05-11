#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar on all detected monitors
for m in $(polybar --list-monitors | cut -d":" -f1); do
     #MONITOR=$m polybar -r bspwm &
     #MONITOR=$m polybar -r quote &
     #MONITOR=$m polybar -r system &
    MONITOR=$m polybar -r fullsize &
done