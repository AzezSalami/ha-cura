## 5.13.0.161 (2026-10-31)
- Update to linuxserver/docker-cura `5.13.0-ls161` (changelog: https://github.com/linuxserver/docker-cura/releases/tag/5.13.0-ls161)

## 5.13.0.161.2 (2026-10-31)
- Republish the plain-HTTP fix from 5.13.0.161.1: the update workflow had reset the version to 5.13.0.161, so Home Assistant never offered the fixed image
- Update workflow: a local fix version such as 5.13.0.161.1 now counts as up to date with upstream 5.13.0-ls161

## 5.13.0.161.1 (2026-10-31)
- Allow plain HTTP: "Open Web UI" now works when Home Assistant is opened over `http://` (the Selkies client no longer stops with "This application requires a secure connection (HTTPS)"). Over HTTP the stream uses JPEG instead of the WebCodecs H.264 decoder, and browser clipboard sync is unavailable
- New optional port 3000 for direct HTTP access (disabled by default)

## 5.13.0.161 (2026-10-30)
- Initial release, based on linuxserver/docker-cura `5.13.0-ls161` (Selkies web desktop, amd64 only)
- Ingress support, persistent profiles in the add-on config folder, `/share` and `/media` linked into Cura's file dialogs
- Optional plain HTTP access on port 3000 (disabled by default), next to HTTPS on 3001
- Prebuilt image published to GHCR; new upstream releases are picked up automatically
