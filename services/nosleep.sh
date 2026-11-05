#!/bin/bash
# /usr/local/bin/nosleep.sh
# Lid-close power manager for Dynabook G83/HU Hackintosh.
#
# Behavior:
#   - Keeps the system awake (prevents deep sleep) while allowing display off.
#   - On lid close: turn the display off (approximate sleep).
#   - On lid open : restore the display immediately.
#
# This lets the machine behave like a "close lid to standby" laptop while
# keeping the running session intact.

PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
LOG=/var/log/nosleep.log

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

# Keep a caffeinate process alive so the system does not enter deep sleep.
# -i idle, -m disk, -s system. (No -d/-u so the display can still be turned off.)
ensure_caffeinate() {
    if ! pgrep -f 'caffeinate -ims' >/dev/null 2>&1; then
        nohup caffeinate -ims >/dev/null 2>&1 &
        log "caffeinate -ims started (pid $!)"
    fi
}

# Keep "disablesleep" enforced.
ensure_sleep_disabled() {
    cur=$(pmset -g 2>/dev/null | awk '/SleepDisabled/{print $2}')
    if [ "$cur" != "1" ]; then
        pmset -a disablesleep 1 2>/dev/null
        log "re-enforced disablesleep=1"
    fi
}

get_clamshell() {
    # returns Yes (closed) / No (open)
    ioreg -r -k AppleClamshellState -d 4 2>/dev/null \
        | grep -o 'AppleClamshellState" = [A-Za-z]*' | tail -1 | awk '{print $3}'
}

display_off() {
    pmset displaysleepnow 2>/dev/null
    log "lid closed -> display off"
}

display_on() {
    # simulate user activity to wake the display
    caffeinate -u -t 3 >/dev/null 2>&1 &
    log "lid opened -> display on"
}

log "=== nosleep.sh started ==="
last_state=""
while true; do
    ensure_caffeinate
    ensure_sleep_disabled
    state=$(get_clamshell)
    if [ "$state" != "$last_state" ]; then
        log "clamshell: $last_state -> $state"
        if [ "$state" = "Yes" ]; then display_off; else display_on; fi
        last_state="$state"
    fi
    sleep 2
done
