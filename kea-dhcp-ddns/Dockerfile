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
    # Install main Kea packaegs
    apk add --no-cache isc-kea-dhcp-ddns~=${VERSION} && \
    # Install ddns hook which is available both in subscription and enterprise
    if [ -n "$TOKEN" ] &&  { [ "$PREMIUM" = "SUBSCRIPTION" ] || [ "$PREMIUM" = "ENTERPRISE" ]; }; then \
    curl -1sLf "https://dl.cloudsmith.io/${TOKEN}/isc/${repo}-prv/setup.alpine.sh" | bash && \
    apk add --no-cache \
        isc-kea-premium-gss-tsig~=${VERSION}; \
    fi && \
    # Revert Cloudsmith repositories
    mv /etc/apk/repositories_backup /etc/apk/repositories && \
    # remove curl and bash
    apk del curl bash

COPY kea-dhcp-ddns.conf /etc/kea/kea-dhcp-ddns.conf

# And give ability to overwrite Kea default config
VOLUME ["/etc/kea"]

# 8000 command control channel
# 53001 ddns
EXPOSE 8000/tcp 53001/udp

CMD ["/usr/sbin/kea-dhcp-ddns", "-c", "/etc/kea/kea-dhcp-ddns.conf"]