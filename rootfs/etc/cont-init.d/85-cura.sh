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

# Upstream (linuxserver/docker-cura) documents this as a hard requirement: with crash reports,
# update checks and notifications enabled, Cura runs out of memory and the kernel kills
# CuraEngine mid-slice ("Backend exited abnormally with return code -9"). Force those
# preferences off in every Cura profile before Cura starts (Cura only reads them at launch).
# Cura creates its profile on first launch, so on a brand-new install this takes effect from
# the second start of the add-on.
CURA_PREFS_OFF=(info/send_slice_info info/asked_send_slice_info=True info/send_engine_crash info/anonymous_engine_crash_report info/automatic_update_check info/automatic_plugin_update_check)
patched=0
shopt -s nullglob
for cfg in "$HOME"/.config/cura/*/cura.cfg; do
    if python3 -I - "$cfg" "${CURA_PREFS_OFF[@]}" << 'EOF'; then
import configparser, sys
path, prefs = sys.argv[1], sys.argv[2:]
parser = configparser.ConfigParser(interpolation=None)
parser.optionxform = str  # keep Cura's key spelling
parser.read(path, encoding="utf-8")
changed = False
for pref in prefs:
    key, _, value = pref.partition("=")
    section, option = key.split("/", 1)
    value = value or "False"
    if not parser.has_section(section):
        parser.add_section(section)
    if parser.get(section, option, fallback=None) != value:
        parser.set(section, option, value)
        changed = True
if changed:
    with open(path, "w", encoding="utf-8") as handle:  # rewrite in place: keeps owner and mode
        parser.write(handle)
sys.exit(0 if changed else 1)
EOF
        bashio::log.info "Disabled crash reports and update checks in ${cfg#"$HOME"/}"
    fi
    patched=$((patched + 1))
done
shopt -u nullglob

if [ "$patched" -eq 0 ]; then
    bashio::log.warning "-------------------------------------------------------------------"
    bashio::log.warning "First start: Cura has not created its preferences yet. Restart the"
    bashio::log.warning "add-on once after Cura has opened, so crash reports and update checks"
    bashio::log.warning "can be switched off; Cura runs out of memory while slicing otherwise."
    bashio::log.warning "-------------------------------------------------------------------"
fi
