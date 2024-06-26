# SPDX-License-Identifier: MPL-2.0

# This Kea docker image provides the following functionality:
# - running Kea DHCPv6 service
# - running Kea control agent (exposes REST API over http)
# - open source hooks
# - possible to build with premium hooks
ARG F_VERSION=38
FROM fedora:${F_VERSION}
LABEL org.opencontainers.image.authors="Kea Developers <kea-dev@lists.isc.org>"

# Add Kea packages from cloudsmith. Make sure the version matches that of the Alpine version.
# Also, install all the open source hooks. When updating, new instructions can
# be found at: https://cloudsmith.io/~isc/repos/kea-2-3/setup/#formats-alpine
ARG F_VERSION=38
ARG K_VERSION=2.4.0-isc20230921141113
ARG TOKEN
ARG PREMIUM

#TODO curl is using -k version to ignore not updated ca-certificates, certificates should be updated rather than mitigate this
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN dnf update -y && \
    # Setup Cloudsmith repo
    if test "$(expr "$(echo "${VERSION}" | cut -d '.' -f 2)" % 2)" = 0; then \
        repo="kea-$(echo "${VERSION}" | cut -d '.' -f 1)-$(echo "${VERSION}" | cut -d '.' -f 2)"; \
    else \
        repo='kea-dev'; \
    fi && \
    curl -1ksLf "https://dl.cloudsmith.io/public/isc/${repo}/setup.rpm.sh" | bash && \
    dnf update && \
    # Install main Kea packaegs and supervisor
    dnf install -y isc-kea-dhcp6-${K_VERSION}.fc${F_VERSION} \
        isc-kea-ctrl-agent-${K_VERSION}.fc${F_VERSION} \
        isc-kea-hooks-${K_VERSION}.fc${F_VERSION} \
        supervisor && \
    # If token is provided add premium Cloudsmith repository
    if [ -n "$TOKEN" ]; then \
    curl -1sLkf "https://dl.cloudsmith.io/${TOKEN}/isc/${repo}-prv/setup.rpm.sh" | bash && \
    dnf update -y && \
    # Install premium Kea hooks
    dnf install -y \
        isc-kea-premium-ddns-tuning-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-flex-id-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-forensic-log-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-host-cmds-${K_VERSION}.fc${F_VERSION}; \
    fi && \
    # Install subscription Kea hooks (provided TOKEN should have access to those pkgs)
    if [ -n "$TOKEN" ] && [ "$PREMIUM" = "SUBSCRIPTION" ]; then \
    dnf install -y \
        isc-kea-premium-cb-cmds-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-class-cmds-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-host-cache-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-lease-query-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-limits-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-subnet-cmds-${K_VERSION}.fc${F_VERSION}; \
    fi && \
    # Install subscription and enterprise Kea hooks (provided TOKEN should have access to those pkgs)
    if [ -n "$TOKEN" ] && [ "$PREMIUM" = "ENTERPRISE" ]; then \
    dnf install -y \
        isc-kea-premium-cb-cmds-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-class-cmds-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-host-cache-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-lease-query-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-limits-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-subnet-cmds-${K_VERSION}.fc${F_VERSION} \
        isc-kea-premium-rbac-${K_VERSION}.fc${F_VERSION}; \
    fi && \
    # Revert Cloudsmith repositories
    rm -rf /etc/yum.repos.d/isc-kea-* && \
    # Create directory for supervisor logs
    mkdir -p /var/log/supervisor && \
    # clean cache
    dnf clean all

VOLUME ["/etc/kea", "/var/lib/kea/"]

# Copy supervisor configs
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor-kea-dhcp6.conf /etc/supervisor/conf.d/kea-dhcp6.conf
COPY supervisor-kea-agent.conf /etc/supervisor/conf.d/kea-agent.conf

# Copy Kea configs
COPY kea-ctrl-agent.conf /etc/kea/kea-ctrl-agent.conf
COPY kea-dhcp6.conf /etc/kea/kea-dhcp6.conf

# 8000 ctrl agent
# 8001 HA MT
# 547 blq
EXPOSE 8000-8001/tcp 547/tcp 547/udp

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
HEALTHCHECK CMD [ "supervisorctl", "status" ]
