#!/usr/bin/env bash
## Author: Nawar
## License: GPL (c) 2014
##
## Note:
## This script used the youtube code of:
##  YouTube XBMC Script 1.0
##  (c) 2013, Tom Laermans - http://tom.laermans.net
##  This script is released into the public domain.
##
## Volume control added by elpraga
## using the command found at http://forum.kodi.tv/showthread.php?tid=176795
## Library Maintenance and skipping forward/back added by uriel1998
## using the command found at http://kodi.wiki/view/HOW-TO:Remotely_update_library
## .kodirc added by uriel1998


function xbmc_req {
    output=$(curl -s -i -X POST --header "Content-Type: application/json" -d "$1" http://$KODI_USER:$KODI_PASS@$KODI_HOST:$KODI_PORT/jsonrpc)

    if [[ $2 = true ]];
    then
        echo $output | jq -C '.'
    fi
}

function parse_json {
    key=$1
    awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$key'\042/){print $(i+1)}}}' | tr -d '"'
}

function play_youtube {

    REGEX="^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*"

    ID=$1

    if [ "$ID" == "" ];
    then
        echo "Syntax $0:$1 <id|url>"
        exit
    fi

    if [[ $ID =~ $REGEX ]]; then
        ID=${BASH_REMATCH[7]}
    fi

    echo -n "Opening video id $ID on $KODI_HOST ..."

    # clear the list
    xbmc_req '{"jsonrpc": "2.0", "method": "Playlist.Clear", "params":{"playlistid":1}, "id": 1}';

    # add the video to the list
    xbmc_req '{"jsonrpc": "2.0", "method": "Playlist.Add", "params":{"playlistid":1, "item" :{ "file" : "plugin://plugin.video.youtube/?action=play_video&videoid='$ID'"}}, "id" : 1}';

    # open the video
    xbmc_req '{"jsonrpc": "2.0", "method": "Player.Open", "params":{"item":{"playlistid":1, "position" : 0}}, "id": 1}';

    echo " done."
}

function play_playlist {
    xbmc_req '{"jsonrpc": "2.0", "method": "Player.Open", "params":{"item":{"playlistid":1, "position" : 0}}, "id": 1}';
}

function list_playlist {
    xbmc_req '{"jsonrpc": "2.0", "method": "Playlist.Getitems", "params":{"playlistid":1, "properties": ["title", "duration", "file"]}, "id": 1}' true
}


function queue_yt_videos {

    REGEX="^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*"

    ID=$1

    if [ "$ID" == "" ];
    then
        echo "Syntax $0:$1 <id|url>"
        exit
    fi

    if [[ $ID =~ $REGEX ]]; then
        ID=${BASH_REMATCH[7]}
    fi

    output=`xbmc_req '{"jsonrpc": "2.0", "method": "Playlist.GetItems", "params":{"playlistid":1}, "id": 99}' true`
    numberitems=`echo $output | parse_json "total"`

    echo -n "Video added to the current playlist $ID on $KODI_HOST which has ($numberitems) items..."
    # add the video to the list
    xbmc_req '{"jsonrpc": "2.0", "method": "Playlist.Add", "params":{"playlistid":1, "item" :{ "file" : "plugin://plugin.video.youtube/?action=play_video&videoid='$ID'"}}, "id" : 1}';

    echo " done."
}

function play_pause {
    # Get Active players first
    output=`xbmc_req '{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 99}' true`
    player_id=`echo $output | parse_json "playerid"`
    echo "Pausing/Playing the player with ID => $player_id"
    xbmc_req '{"jsonrpc": "2.0", "method": "Player.PlayPause", "params": { "playerid": '$player_id' }, "id": 1}'
}

function stop {
    # Get Active players first
    output=`xbmc_req '{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 99}' true`
    player_id=`echo $output | parse_json "playerid"`
    echo "Stopping the player with ID => $player_id"
    xbmc_req '{"jsonrpc": "2.0", "method": "Player.Stop", "params": { "playerid": '$player_id' }, "id": 1}'
}

function skip_forward {
    # Get Active players first
    output=`xbmc_req '{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 99}' true`
    player_id=`echo $output | parse_json "playerid"`
    echo "Skipping forward the player with ID => $player_id"
    xbmc_req '{"jsonrpc": "2.0", "method": "Player.Seek", "params": { "playerid": '$player_id', "value" : "smallforward" }, "id": 1}'
}

function skip_backward {
    # Get Active players first
    output=`xbmc_req '{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 99}' true`
    player_id=`echo $output | parse_json "playerid"`
    echo "Skipping back with the player with ID => $player_id"
    xbmc_req '{"jsonrpc": "2.0", "method": "Player.Seek", "params": { "playerid": '$player_id', "value" : "smallbackward" }, "id": 1}'
}

function send_text {
    echo "Sending the text"
    xbmc_req '{"jsonrpc": "2.0", "method": "Input.SendText", "params": { "text": "'$1'" }}'
}

function update_libraries {
    echo "Updating the video libraries"
    xbmc_req '{"jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}'
    echo "Updating the audio libraries"
    xbmc_req '{"jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}'

}

function clean_libraries {
    echo "Cleaning the libraries"
    xbmc_req '{"jsonrpc": "2.0", "method": "AudioLibrary.Clean", "id": "mybash"}'
    xbmc_req '{"jsonrpc": "2.0", "method": "VideoLibrary.Clean", "id": "mybash"}'
}


function press_key {

    ACTION=''
    CLR="\e[K"

    case "$1" in
        A) ACTION='Up'
            echo -ne "\rUp$CLR";
            ;;
        B) ACTION='Down'
            echo -ne "\rDown$CLR";
            ;;
        C) ACTION='Right'
            echo -ne "\rRight$CLR";
            ;;
        D) ACTION='Left'
            echo -ne "\rLeft$CLR";
            ;;
        c) ACTION='ContextMenu'
            echo -ne "\rContext Menu$CLR";
            ;;
        i) ACTION='Info'
            echo -ne "\rInformation$CLR";
            ;;
        $'\177') ACTION='Back'
            echo -ne "\rBack$CLR";
            ;;
        "") ACTION='Select'
            echo -ne "\rSelect$CLR";
            ;;
    esac

    if [[ "$ACTION" != " " ]] && [[ $LOCK == false  ]]
    then
        LOCK=true
        xbmc_req '{"jsonrpc": "2.0", "method": "Input.'$ACTION'"}'
        LOCK=false
    fi
}

function handle_keys {
    echo "Interactive navigation key: ";
    while :
    do
        read  -s -n1 key

        if [[ $key = q ]]
        then
            break
        elif [[ $key != ' ' ]]
        then
            press_key "$key"
        fi
    done
}

function volume_up {
    echo "Incrementing volume"
    xbmc_req '{ "jsonrpc": "2.0", "method": "Application.SetVolume", "params": { "volume": "increment" }, "id": 1 }'
}

function volume_down {
    echo "Decrementing volume on"
    xbmc_req '{ "jsonrpc": "2.0", "method": "Application.SetVolume", "params": { "volume": "decrement" }, "id": 1 }'
}

function handle_volume {
    echo "Press up/down for volume adjustment (q to quit): ";
    while :
    do
        read  -s -n1 key
        if [[ $key = q ]];then
            printf "\n"
            break
        elif [[ $key == 'A' ]]; then
            printf "\r+ Volume increasing."
            xbmc_req '{ "jsonrpc": "2.0", "method": "Application.SetVolume", "params": { "volume": "increment" }, "id": 1 }'
        elif [[ $key == 'B' ]];then
            printf "\r- Volume decreasing."
            xbmc_req '{ "jsonrpc": "2.0", "method": "Application.SetVolume", "params": { "volume": "decrement" }, "id": 1 }'
        fi
    done
}

function fullscreen_toggle {
    # Get Active players first
    output=`xbmc_req '{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 99}' true`
    player_id=`echo $output | parse_json "playerid"`
    echo "Toggle fullscreen on the player with ID => $player_id"
    xbmc_req '{ "jsonrpc": "2.0", "method": "GUI.SetFullscreen", "params": { "fullscreen": "toggle" }, "id": 1 }'
}

function show_help {

echo -e "\n kodi-cli -[p|i|h|s|y youtube URL/ID|t 'text to send']\n\n" \
    "-p Play/Pause the current played video\n" \
    "-s Stop the current played video\n" \
    "-j Skip forward in the current played video\n" \
    "-k Skip backward in the current played video\n" \
    "-y play youtube video. Use either URL/ID (of video)\n" \
    "-q queue youtube video to the current list. Use either URL/ID (of video). Use instead of -y.\n" \
    "-o play youtube video directly on Kodi. Use the name of video.\n" \
    "-v interactive volume control\n" \
    "-i interactive navigation mode. Accept keyboard keys of Up, Down, Left, Right, Back,\n" \
    "   Context menu and information\n" \
    "-l Play default playlist (most useful after using -q a few times)\n" \
    "-t title of playlist entry\n" \
    "-u Increment the volume on Kodi\n" \
    "-d Decrement the volume on Kodi\n" \
    "-f toggle fullscreen\n" \
    "-m Update libraries\n" \
    "-n clean libraries\n" \
    "-h showing this help message\n"

}

## main
## check Bash version compatibility
if ((BASH_VERSINFO[0] < 4)); then
    echo -e "Error: $0 requires Bash version 4+"
    exit 1
fi
## check if we have any argument
if [ $# -eq 0 ];then
	echo -e "\n failure: make sure there is at least one argument"
	show_help
	exit
fi

## ---- Configuration --- ##
## Configure your KODI RPC details here
KODI_HOST=
KODI_PORT=
KODI_USER=
KODI_PASS=
LOCK=false

# If the script does not have configuration hardcoded, the script will
# search for it in $HOME/.kodirc

if [ -z "$KODI_HOST" ]; then
    if [ -f "$HOME/.kodirc" ];then
        readarray -t line < "$HOME/.kodirc"
        KODI_HOST=${line[0]}
        KODI_PORT=${line[1]}
        KODI_USER=${line[2]}
        KODI_PASS=${line[3]}
    fi
fi

# Ensure some configuration is loaded, or exit.
if [ -z "$KODI_HOST" ]; then
	echo -e "\n failure: Some Kodi configurations are not loaded. Please make sure they are."
	show_help
	exit
fi

## Process command line arguments
while getopts "yqopstiudfhvmnjkl" opt; do
    case $opt in
        l)  #play default playlist
            # play_playlist
            list_playlist
            ;;
        y)
            #play youtube video
            play_youtube $2
            ;;
        q)
            #queue youtube video
            queue_yt_videos $2
            ;;
        o)
            #play youtube video directly
            #this depends on using mps-youtube
            play_youtube `mpsyt /$2, i 1, q | grep -i link | awk -F 'v=' '{ print $2 }'`
            ;;
        p)
            play_pause
            ;;
        s)
            stop
            ;;
        t)
            # send_text $2
            # handle_keys
            ;;
        i)
            handle_keys
            ;;
        u)
            volume_up
            ;;
        d)
            volume_down
            ;;
        f)
            fullscreen_toggle
            ;;
        h)
            show_help
            ;;
        m)
            update_libraries
            ;;
        n)
            clean_libraries
            ;;
        v)
            handle_volume
            ;;
        j)
            skip_forward
            ;;
        k)
            skip_backward
            ;;

    esac
done



