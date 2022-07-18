#!/bin/bash

# this script is invoced every 6 minutes if clipboard is set to 'RUN', then a speedtest runs


while true
do

    # wait 65 seconds then try again
    sleep 65

    # if clipboard is set to 'RUN'
    clipboard="$(DISPLAY=:0 xclip -o)"
    #if [ "$clipboard" == "RUN" ] || [ -f "/RUN" ]

    # check if /RUN File exists, and time is past 7:30
    if [[ -f "/RUN" ]] && [[ $(date +%H:%M) > "07:30" ]]
    then
        echo "Tring to start speedtest..."
        
        # messung durchfuehren
        DISPLAY=:0 xdotool mousemove 531 510
        DISPLAY=:0 xdotool click 1


        # haeckchen
        DISPLAY=:0 xdotool mousemove 694 405
        DISPLAY=:0 xdotool click 1
        DISPLAY=:0 xdotool mousemove 694 479
        DISPLAY=:0 xdotool click 1
        DISPLAY=:0 xdotool mousemove 694 551
        DISPLAY=:0 xdotool click 1

        DISPLAY=:0 xdotool mousemove 1169 405
        DISPLAY=:0 xdotool click 1
        DISPLAY=:0 xdotool mousemove 1169 479
        DISPLAY=:0 xdotool click 1
        DISPLAY=:0 xdotool mousemove 1169 551
        DISPLAY=:0 xdotool click 1

        # messung starten
        DISPLAY=:0 xdotool mousemove 1091 668
        DISPLAY=:0 xdotool click 1


        # wait 5:05 minutes
        sleep 260
        echo "waiting 5 minutes..."

    else
        echo "RUN not set in clipboard or file /RUN not available. (value in clipboard is $clipboard)"
    fi

done



# xdotool getmouselocation

