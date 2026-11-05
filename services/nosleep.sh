#!/bin/bash
# /usr/local/bin/nosleep.sh
# Lid-close keep-awake guardian for Dynabook G83/HU Hackintosh.
#
# Policy (v2 — validated):
#   - The system must NOT enter deep sleep (S3 hangs on this firmware).
#   - The system must NOT be asked to turn the display off via "displaysleepnow":
#     doing so triggers a WEX eDP DBUF power-up bug on lid reopen
#     ("DBUF 2 power up timeout" -> "FB0 is not enabled" -> black screen).
#   - Let macOS handle display power naturally on lid close; on lid open it
#     restores the panel by itself (verified: bl 3->2->0 on close, 0->3 in <1s on open).
#
# This script only keeps "disablesleep=1" enforced. caffeinate is managed by a
# separate launchd service (com.local.keepawake); no display commands are issued.

PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
LOG=/var/log/nosleep.log

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

ensure_sleep_disabled() {
    cur=$(pmset -g 2>/dev/null | awk '/SleepDisabled/{print $2}')
    if [ "$cur" != "1" ]; then
        pmset -a disablesleep 1 2>/dev/null
        log "re-enforced disablesleep=1"
    fi
}

log "=== nosleep.sh v2 started (disablesleep guardian; no display commands) ==="
while true; do
    ensure_sleep_disabled
    sleep 5
done
