# SPDX-License-Identifier: MPL-2.0

# This Kea docker image provides the following functionality:
# - running Kea DHCP DDNS service
# - running Kea control agent (exposes REST API over http)
# - open source hooks
# - possible to build with premium hooks

FROM debian:12
LABEL org.opencontainers.image.authors="Kea Developers <kea-dev@lists.isc.org>"

# Add Kea packages from cloudsmith. Make sure the version matches that of the Alpine version.
# Also, install all the open source hooks. When updating, new instructions can
# be found at: https://cloudsmith.io/~isc/repos/kea-2-3/setup/#formats-alpine
ARG VERSION=2.4.0-isc20230921141113
ARG TOKEN
ARG PREMIUM

#TODO curl is using -k version to ignore not updated ca-certificates, certificates should be updated rather than mitigate this
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y curl bash && \
    # Setup Cloudsmith repo
    if test "$(expr "$(echo "${VERSION}" | cut -d '.' -f 2)" % 2)" = 0; then \
        repo="kea-$(echo "${VERSION}" | cut -d '.' -f 1)-$(echo "${VERSION}" | cut -d '.' -f 2)"; \
    else \
        repo='kea-dev'; \
    fi && \
    curl -1ksLf "https://dl.cloudsmith.io/public/isc/${repo}/setup.deb.sh" | bash && \
    apt-get update && \
    # Install main Kea packaegs and supervisor
    apt-get install --no-install-recommends -y isc-kea-dhcp-ddns=${VERSION} isc-kea-ctrl-agent=${VERSION} supervisor && \
    # If token is provided add premium Cloudsmith repository
    if [ -n "$TOKEN" ] && { [ "$PREMIUM" = "SUBSCRIPTION" ] || [ "$PREMIUM" = "ENTERPRISE" ]; } then \
    curl -1sLkf "https://dl.cloudsmith.io/${TOKEN}/isc/${repo}-prv/setup.deb.sh" | bash && \
    apt-get update && \
    # Install premium Kea hooks
    apt-get install --no-install-recommends -y \
        isc-kea-premium-gss-tsig=${VERSION}; \
    fi && \
    # Revert Cloudsmith repositories
    rm -rf /etc/apt/sources.list.d/isc-kea-* && \
    # Create directory for supervisor logs
    mkdir -p /var/log/supervisor && \
    # clean cache
    apt-get clean

VOLUME ["/etc/kea", "/var/lib/kea/"]

# Copy supervisor configs
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor-kea-dhcp-ddns.conf /etc/supervisor/conf.d/kea-dhcp-ddns.conf
COPY supervisor-kea-agent.conf /etc/supervisor/conf.d/kea-agent.conf

# Copy Kea configs
COPY kea-ctrl-agent.conf /etc/kea/kea-ctrl-agent.conf
COPY kea-dhcp-ddns.conf /etc/kea/kea-dhcp-ddns.conf

# 8000 ctrl agent
# 8001 HA MT
# 547 blq
EXPOSE 8000/tcp 53001/udp

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
HEALTHCHECK CMD [ "supervisorctl", "status" ]
