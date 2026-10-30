#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Cura-specific setup. Runs after 20-folders.sh has settled HOME and ownership.

# Make Home Assistant's shared folders easy to reach from Cura's Open/Save dialogs, so models
# can be loaded from /share or /media and G-code saved back there (e.g. for a Samba share or
# an OctoPrint/Moonraker upload watcher).
for target in /share /media; do
    link="$HOME/HA_${target#/}"
    if [ -d "$target" ] && [ ! -e "$link" ]; then
        ln -s "$target" "$link"
        bashio::log.info "Linked $target to $link for Cura's file dialogs"
    fi
done

# Upstream (linuxserver/docker-cura) documents this as a hard requirement: without it Cura
# runs out of memory and crashes. It can only be set from inside Cura, so remind the user.
if ! grep -rqs "send_slice_info = False" "$HOME/.config/cura" 2> /dev/null; then
    bashio::log.warning "-------------------------------------------------------------------"
    bashio::log.warning "First start: in Cura open Preferences > Configure Cura > General and"
    bashio::log.warning "DISABLE crash reports, update checks and notifications."
    bashio::log.warning "Upstream reports Cura will run out of memory and crash otherwise."
    bashio::log.warning "-------------------------------------------------------------------"
fi
