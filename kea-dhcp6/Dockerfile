# SPDX-License-Identifier: MPL-2.0

# This Kea docker image provides the following functionality:
# - running Kea DHCPv6 service
# - running Kea control agent (exposes REST API over http)
# - open source hooks
# - possible to build with premium hooks

FROM alpine:3.21
LABEL org.opencontainers.image.authors="Kea Developers <kea-dev@lists.isc.org>"

# Add Kea packages from cloudsmith. Make sure the version matches that of the Alpine version.
# Also, install all the open source hooks. When updating, new instructions can
# be found at: https://cloudsmith.io/~isc/repos/kea-2-5/setup/#formats-alpine
ARG VERSION=2.7
ARG TOKEN
ARG PREMIUM

SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN cp /etc/apk/repositories /etc/apk/repositories_backup && \
    # Install curl and bash for cloudsmith's script. Tzdata to allow timezone change.
    apk update && apk add --no-cache curl bash tzdata && \
    # Setup Cloudsmith repo
    if test "$(expr "$(echo "${VERSION}" | cut -d '.' -f 2)" % 2)" = 0; then \
        repo="kea-$(echo "${VERSION}" | cut -d '.' -f 1)-$(echo "${VERSION}" | cut -d '.' -f 2)"; \
    else \
        repo='kea-dev'; \
    fi && \
    curl -1sLf "https://dl.cloudsmith.io/public/isc/${repo}/setup.alpine.sh" | bash && \
    apk update && \
    # Install main Kea packaegs and supervisor
    apk add --no-cache isc-kea-dhcp6~=${VERSION} isc-kea-hooks~=${VERSION} && \
    # If token is provided add premium Cloudsmith repository
    if [ -n "$TOKEN" ]; then \
    curl -1sLf "https://dl.cloudsmith.io/${TOKEN}/isc/${repo}-prv/setup.alpine.sh" | bash && \
    apk update && \
    # Install premium Kea hooks
    apk add --no-cache \
        isc-kea-premium-ddns-tuning~=${VERSION} \
        isc-kea-premium-flex-id~=${VERSION} \
        isc-kea-premium-forensic-log~=${VERSION} \
        isc-kea-premium-host-cmds~=${VERSION}; \
    fi && \
    # Install subscription Kea hooks (provided TOKEN should have access to those pkgs)
    if [ -n "$TOKEN" ] && [ "$PREMIUM" = "SUBSCRIPTION" ]; then \
    apk add --no-cache \
        isc-kea-premium-cb-cmds~=${VERSION} \
        isc-kea-premium-class-cmds~=${VERSION} \
        isc-kea-premium-host-cache~=${VERSION} \
        isc-kea-premium-lease-query~=${VERSION} \
        isc-kea-premium-limits~=${VERSION} \
        isc-kea-premium-radius~=${VERSION} \
        isc-kea-premium-subnet-cmds~=${VERSION}; \
    fi && \
    # Install subscription and enterprise Kea hooks (provided TOKEN should have access to those pkgs)
    if [ -n "$TOKEN" ] && [ "$PREMIUM" = "ENTERPRISE" ]; then \
    apk add --no-cache \
        isc-kea-premium-cb-cmds~=${VERSION} \
        isc-kea-premium-class-cmds~=${VERSION} \
        isc-kea-premium-host-cache~=${VERSION} \
        isc-kea-premium-lease-query~=${VERSION} \
        isc-kea-premium-limits~=${VERSION} \
        isc-kea-premium-radius~=${VERSION} \
        isc-kea-premium-subnet-cmds~=${VERSION} \
        isc-kea-premium-rbac~=${VERSION}; \
    fi && \
    # Revert Cloudsmith repositories
    mv /etc/apk/repositories_backup /etc/apk/repositories && \
    # remove curl and bash
    apk del curl bash

VOLUME ["/etc/kea", "/var/lib/kea/"]

# Copy Kea config
COPY kea-dhcp6.conf /etc/kea/kea-dhcp6.conf

# 8000 command control channel
# 8001 HA MT
# 547 blq
EXPOSE 8000-8001/tcp 547/tcp 547/udp

CMD ["/usr/sbin/kea-dhcp6", "-c", "/etc/kea/kea-dhcp6.conf"]