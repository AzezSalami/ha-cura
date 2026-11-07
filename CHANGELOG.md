## 5.14.0.164 (2026-11-07)
- Update to linuxserver/docker-cura `5.14.0-ls164` (changelog: https://github.com/linuxserver/docker-cura/releases/tag/5.14.0-ls164)

## 5.14.0.163 (2026-11-06)
- Update to linuxserver/docker-cura `5.14.0-ls163` (changelog: https://github.com/linuxserver/docker-cura/releases/tag/5.14.0-ls163)

## 5.13.0.162 (2026-11-02)
- Update to linuxserver/docker-cura `5.13.0-ls162` (changelog: https://github.com/linuxserver/docker-cura/releases/tag/5.13.0-ls162)

## 5.13.0.161.3 (2026-10-31)
- Fix slicing failing with "Backend exited abnormally with return code -9": crash reports, slice statistics and update checks are now switched off in Cura's preferences at every start. linuxserver/docker-cura documents that Cura runs out of memory otherwise. On a new install this applies from the second start of the add-on

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
