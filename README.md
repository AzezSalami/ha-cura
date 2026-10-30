# Home Assistant add-on: Cura

[UltiMaker Cura](https://ultimaker.com/software/ultimaker-cura/) is a free, easy-to-use 3D-printing slicer with 400+ settings. This add-on runs the full Cura desktop app inside Home Assistant and streams it to your browser (sidebar via Ingress, or HTTPS port).

Based on the image <https://github.com/linuxserver/docker-cura>, wrapped the same way as the Selkies desktop add-ons (Claude Desktop, Webtop, Chromium) in <https://github.com/alexbelgium/hassio-addons>.

**Architecture:** amd64 only — upstream Cura publishes no ARM build.

## Installation

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FAzezSalami%2Fha-cura)

1. Click the button above, or in Home Assistant go to **Settings → Add-ons → Add-on store → ⋮ → Repositories** and add
   `https://github.com/AzezSalami/ha-cura` and click *Add*.
2. Refresh the store, open **Cura**, click *Install*, then *Start*.

## Updates

A GitHub Action in this repository checks [linuxserver/docker-cura](https://github.com/linuxserver/docker-cura/releases) every day. When there is a new release it bumps the add-on version, builds the image and publishes it to `ghcr.io/azezsalami/cura-amd64`. You can also start it by hand under **Actions → Update and build Cura add-on → Run workflow**. Home Assistant then shows the update like any other add-on: click *Update*, or turn on *Auto update* on the add-on page. Your Cura profiles in `/config` are kept.

Versions follow the upstream tag: `5.13.0-ls161` becomes add-on version `5.13.0.161` (Cura version + linuxserver build number).

## First start – required

In Cura open **Preferences → Configure Cura → General** and **disable crash reports, update checks and notifications**. Upstream documents that Cura runs out of memory and crashes otherwise. The add-on log prints this reminder until it's done.

## Configuration

| Option | Description |
| --- | --- |
| `PUID` / `PGID` | User Cura runs as. `0` (default) gives full access to `/share` and `/media`. |
| `PASSWORD` | Password for the desktop user. **Set this if you open port 3001.** |
| `TZ` | Timezone, e.g. `Europe/Berlin`. |
| `KEYBOARD` | Keyboard layout. |
| `DRINODE` | GPU render node for hardware acceleration (e.g. `/dev/dri/renderD128`). |
| `PIXELFLUX_WAYLAND` | Upstream uses Wayland by default (needs an AVX2 CPU, falls back to X11 otherwise). Set `false` to force X11 if the stream stays black. |
| `MAX_RES` | Cap the virtual screen, e.g. `1920x1080`, if performance is poor. |
| `data_location` | Where Cura's profiles live. Default `/config` = `/addon_configs/<id>_cura` on the host, included in backups. |
| `localdisks` / `networkdisks` | Mount local or SMB disks (alexbelgium modules). |
| `additional_apps` | Extra apt packages, comma separated. |
| `env_vars` | Any extra Selkies/LSIO environment variable (see upstream README). |

### Files
`/share` and `/media` are linked into Cura's home as `HA_share` and `HA_media`, so you can open STL/3MF files and save G-code there. You can also upload/download through the Selkies sidebar.

### Access
- **Ingress:** sidebar → Cura.
- **Direct:** enable port `3001` in the Network section, then open `https://<ha-ip>:3001` (self-signed cert; HTTPS is required by Selkies).

## Notes
- Home Assistant ignores `shm_size`; the image copes with the default `/dev/shm`.
- Cura is heavy: plan for 2–4 GB RAM while slicing.
