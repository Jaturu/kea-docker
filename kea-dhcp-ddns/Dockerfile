# SPDX-License-Identifier: MPL-2.0

# This Kea docker image provides the following functionality:
# - running Kea DHCPv6 service
# - running Kea control agent (exposes REST API over http)
# - open source hooks
# - possible to build with premium hooks

FROM alpine:3.18
LABEL org.opencontainers.image.authors="Kea Developers <kea-dev@lists.isc.org>"

# Add Kea packages from cloudsmith. Make sure the version matches that of the Alpine version.
# Also, install all the open source hooks. When updating, new instructions can
# be found at: https://cloudsmith.io/~isc/repos/kea-2-3/setup/#formats-alpine
ARG VERSION=2.5
ARG TOKEN
ARG PREMIUM

SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN cp /etc/apk/repositories /etc/apk/repositories_backup && \
    # Install curl
    apk update && apk add --no-cache curl bash && \
    # Setup Cloudsmith repo
    curl -1sLf "https://dl.cloudsmith.io/public/isc/kea-$(echo "${VERSION}" | cut -c1;)-$(echo "${VERSION}" | cut -c3;)/setup.alpine.sh" | bash && \
    apk update && \
    # Install main Kea packaegs
    apk add --no-cache isc-kea-dhcp-ddns~=${VERSION} isc-kea-ctrl-agent~=${VERSION} supervisor && \
    # Install ddns hook which is available both in subscription and enterprise
    if [ -n "$TOKEN" ] &&  { [ "$PREMIUM" = "SUBSCRIPTION" ] || [ "$PREMIUM" = "ENTERPRISE" ]; }; then \
    curl -1sLf "https://dl.cloudsmith.io/${TOKEN}/isc/kea-$(echo "${VERSION}" | cut -c1;)-$(echo "${VERSION}" | cut -c3;)-prv/setup.alpine.sh" | bash && \
    apk add --no-cache \
        isc-kea-premium-gss-tsig~=${VERSION}; \
    fi && \
    # Revert Cloudsmith repositories
    mv /etc/apk/repositories_backup /etc/apk/repositories && \
    # Create directory for supervisor logs
    mkdir -p /var/log/supervisor && \
    # remove curl
    apk del curl

# Copy supervisor configs
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor-kea-dhcp-ddns.conf /etc/supervisor/conf.d/kea-dhcp-ddns.conf
COPY supervisor-kea-agent.conf /etc/supervisor/conf.d/kea-agent.conf

# Copy Kea configs
COPY kea-ctrl-agent.conf /etc/kea/kea-ctrl-agent.conf
COPY kea-dhcp-ddns.conf /etc/kea/kea-dhcp-ddns.conf

# And give ability to overwrite Kea default config

VOLUME ["/etc/kea"]

# 8000 ctrl agent
# 8001 HA MT
# 547 blq
EXPOSE 8000/tcp 53001/udp

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
HEALTHCHECK CMD [ "supervisorctl", "status" ]