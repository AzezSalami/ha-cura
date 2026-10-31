#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#=== Home Assistant Addon ===#

#################
# 1 Build Image #
#################

ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}
ARG BUILD_ARCH

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

USER root

# load volume
VOLUME [ "/sys/fs/cgroup" ]

# Home of the desktop user = persistent add-on config folder (/addon_configs/<slug> on the host).
# 20-folders.sh reads this back as the default data_location.
# hadolint ignore=SC2015,DL4006,SC2013,SC2086
RUN \
    usermod --home /config abc && \
    if [ -d /etc/services.d ] && ls /etc/services.d/*/run 1> /dev/null 2>&1; then sed -i "1a set +e" /etc/services.d/*/run; fi

# Shared alexbelgium build/runtime helpers are downloaded at build time, so this add-on also
# builds outside the alexbelgium repository (your own fork, or a local /addons build).
ARG TEMPLATE_BASE_URL="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates"

# Global LSIO modifications
ARG CONFIGLOCATION="/config"
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_lsio.sh "${TEMPLATE_BASE_URL}/ha_lsio.sh" && \
    chmod 744 /ha_lsio.sh && \
    if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && \
    rm /ha_lsio.sh

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /
RUN find /etc/cont-init.d -type f -name "*.sh" -print -exec chmod +x {} \;

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Fix Selkies startup when PulseAudio module initialization fails
RUN if [ -f /etc/s6-overlay/s6-rc.d/svc-selkies/run ]; then \
        sed -i "1a\set +e" /etc/s6-overlay/s6-rc.d/svc-selkies/run; \
    fi

# Allow plain-HTTP access (e.g. Home Assistant on http://homeassistant.local:8123).
# The Selkies web client refuses to start when the page is not a "secure context", although
# everything it needs then has a fallback: video drops to the JPEG encoder (no WebCodecs),
# and clipboard sync and file upload already check for the APIs they use. A tiny script at
# the top of each dashboard page reports the page as secure before the client loads, so it
# takes those fallbacks instead of stopping. On HTTPS the browser already reports a secure
# context and the script does nothing. Patched in the dashboard sources, which init-nginx
# copies to /usr/share/selkies/web on every start.
# hadolint ignore=SC2016
RUN marker="ha-cura-allow-http"; \
    shim='<script>/*'"$marker"'*/if(!window.isSecureContext){try{Object.defineProperty(window,"isSecureContext",{get:function(){return true},configurable:true})}catch(e){}}</script>'; \
    patched=0; \
    for page in /usr/share/selkies/*/index.html; do \
        [ -f "$page" ] || continue; \
        if grep -q "$marker" "$page"; then patched=$((patched + 1)); continue; fi; \
        grep -q "<head>" "$page" || continue; \
        sed -i "0,/<head>/s||<head>${shim}|" "$page"; \
        echo "Allowed plain HTTP in $page"; \
        patched=$((patched + 1)); \
    done; \
    if [ "$patched" -eq 0 ]; then echo "WARNING: no Selkies dashboard page patched; plain HTTP access stays blocked"; fi

# Modules
ARG MODULES="00-banner.sh 00-global_var.sh 01-custom_script.sh 00-local_mounts.sh 00-smb_mounts.sh 90-dns_set.sh"

# BUILD_DATE busts this layer's cache so rebuilds pick up template changes
ARG BUILD_DATE=unknown

# Automatic modules download
RUN echo "Build date marker: ${BUILD_DATE}" && \
    curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_automodules.sh "${TEMPLATE_BASE_URL}/ha_automodules.sh" && \
    chmod 744 /ha_automodules.sh && \
    /ha_automodules.sh "$MODULES" && \
    rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="nginx"

# Automatic apps & bashio
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_autoapps.sh "${TEMPLATE_BASE_URL}/ha_autoapps.sh" && \
    chmod 744 /ha_autoapps.sh && \
    /ha_autoapps.sh "$PACKAGES" && \
    rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint and standalone bashio compatibility
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_entrypoint.sh "${TEMPLATE_BASE_URL}/ha_entrypoint.sh" && \
    curl -fsSL --retry 3 --retry-delay 2 \
        -o /usr/local/lib/bashio-standalone.sh "${TEMPLATE_BASE_URL}/bashio-standalone.sh" && \
    chmod 0777 /ha_entrypoint.sh && \
    chmod 0755 /usr/local/lib/bashio-standalone.sh

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/ha_entrypoint.sh" ]

############
# 5 Labels #
############

ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ENV BUILD_VERSION="${BUILD_VERSION}"
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

####################
# 6 HealthcheckNOT #
####################
# Like the other Selkies desktop add-ons, no Docker HEALTHCHECK: the desktop stack can take
# longer than a probe window to come up on slow hosts, and a failed probe restarts the add-on.
