#!/bin/sh
. ./.env
while getopts 'v:' OPTION; do
  case "$OPTION" in
    v)
      VERSION="$OPTARG"
      ;;
    ?)
      echo "script usage: ./build_images.sh [-v keaversion]" >&2
      echo "Provide kea version in X.Y.Z format or precise package name. For example: 2.3.8 or 2.3.8-r20230530063557" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

echo "Kea version selected $VERSION"
DIRECTORY="$PWD"
cd ../kea-dhcp4
docker build --tag kea-dhcp4:${VERSION} --build-arg VERSION=${VERSION} .
cd ../kea-dhcp6
docker build --tag kea-dhcp6:${VERSION} --build-arg VERSION=${VERSION} .
cd "${DIRECTORY}"
mkdir -p initdb
wget https://gitlab.isc.org/isc-projects/kea/raw/Kea-$(echo "${VERSION}" | cut -c1;).$(echo "${VERSION}" | cut -c3;).$(echo "${VERSION}" | cut -c5;)/src/share/database/scripts/pgsql/dhcpdb_create.pgsql -O ./initdb/dhcpdb_create.sql

tee "config/kea/subnets4.json" > /dev/null <<EOF
"subnet4": [
  {
  "subnet": "$SUBNET4",
  "pools": [
    {
      "pool": "$POOL4"
    }
  ],
  "interface": "eth0"
  }
]
EOF

tee "config/kea/subnets6.json" > /dev/null <<EOF
"subnet6": [
  {
  "subnet": "$SUBNET6",
  "pools": [
    {
      "pool": "$POOL6"
    }
  ],
  "interface": "eth0"
  }
]
EOF
