#!/bin/sh

script_path=$(cd "$(dirname "${0}")" && pwd)
cd "${script_path}" || exit

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
shift "$((OPTIND -1))"

echo "Kea version selected $VERSION"
cd "${script_path}"/../kea-dhcp4 || exit
docker build --tag kea-dhcp4:"${VERSION}" --build-arg VERSION="${VERSION}" .
cd "${script_path}"/../kea-dhcp6 || exit
docker build --tag kea-dhcp6:"${VERSION}" --build-arg VERSION="${VERSION}" .
cd "${script_path}" || exit
mkdir -p initdb
wget "https://gitlab.isc.org/isc-projects/kea/raw/Kea-$(echo "${VERSION}" | cut -c1;).$(echo "${VERSION}" | cut -c3;).$(echo "${VERSION}" | cut -c5;)/src/share/database/scripts/pgsql/dhcpdb_create.pgsql" -O ./initdb/dhcpdb_create.sql

cat > "config/kea/subnets4.json" <<EOF
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

cat > "config/kea/subnets6.json" <<EOF
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
