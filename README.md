# Docker files for building Kea containers

This repository contains Docker files used to build official Kea images.
You can use them to build images locally with desired modifications.
Also, Kea-Compose server allows for rapid deployment of Kea with IPv4, IPv6 and PostgerSQL database.

Those Docker files and images are based on Alpine 3.17.

Table of contents:
1. [Using Official Kea Images on Cloudsmith](#using-official-kea-images-on-cloudsmith)
    1. [Cloudsmith repository](#cloudsmith-repository)
    1. [Requirements](#requirements)
    1. [Volumes](#volumes)
    1. [Networks](#networks)
    1. [Ports](#ports)
    1. [Examples](#examples)
1. [Using Dockerfiles](#using-dockerfiles)
    1. [Preparing Volumes](#preparing-volumes)
    1. [Building image](#building-image)
    1. [Running the image](#running-the-image)
1. [Kea configuration](#kea-configuration)
1. [Kea-Compose script](#kea-compose-script)
1. [Other](#other)
    1. [Docker issues](#docker-issues)
    1. [Support](#support)
    1. [Documentation](#documentation)
    1. [Issues](#issues)
    1. [License](#license)

# Using Official Kea Images on Cloudsmith

## Cloudsmith repository

Kea officialy released images are published on Cloudsmith repository: https://cloudsmith.io/~isc/repos/docker/packages/
Cloudsmith provides "Set Me Up" instructions about using its repository.

You can refer to images using this naming pattern:
```
docker.cloudsmith.io/isc/docker/<image-name>:<version>
```

Replace `<image-name>` with one of the images and `<version>` with the numerical version or appropriate tag.

For example:
```
docker.cloudsmith.io/isc/docker/kea-dhcp4:2.5.2
```

We strongly encourage you to analyze [Kea-Compose script](#kea-compose-script), which contains a working example of docker deployment.

## Requirements

Kea images should be provided with configuration files and have proper docker network to work correctly.
(If you don't provide a configuration file, the server will run an example config file.)

For Kea v6 you need to have IPv6 enabled in docker engine. \
(more informations: https://docs.docker.com/config/daemon/ipv6/)


### Volumes

You can mount these volumes to kea containers:
- `/etc/kea` - Folder containing configuration files
- `/var/lib/kea/` - Folder containing leases file

You can use this parameter for `docker run` command:
```shell
--volume=local_path:container_path
```
Eg.
```shell
--volume=./config/kea:/etc/kea
```

### Networks

It is not recommended to bind the container to the "host" network - this will collide any with other DHCP servers on any network that the host is connected to and may cause losing connection to the host.

To bind container to specific physical (or vlan) interface you need to create "IPVlan" docker network.
Please note that host will not be able to reach containers using interface used by IPVlan network.

(Remove `--ipv6` and v6 subnet if not needed.)

```shell
docker network create --driver ipvlan --ipv6 --subnet <subnet> --opt parent=<host-interface> <new-network-name>
```
Eg.
```shell
docker network create --driver ipvlan --ipv6 --subnet 192.168.50.0/24 --subnet 2001:db8:1::/64 --opt parent=enp0s9 ipvlan0
```

Then add parameter to `docker run` command:
```shell
--net [new-network-name]
```

Kea DDNS does not need to be run using IPVlan network. It can be bound using default docker bridge with port forwarding.

### Ports

When using multiple docker networks, you can bind specific ports to host for using bridged network and port binding.

List of available ports.

Kea DHCP v4:
- 67/tcp - Bulk Leasequery
- 67/udp - DHCP port (Only Relay traffic will be forwarded)
- 8000/tcp - Control Agent
- 8001/tcp - High Availability communication

Kea DHCP v6:
- 547/tcp - Bulk Leasequery
- 547/udp - DHCP port (Only Relay traffic will be forwarded)
- 8000/tcp - Control Agent
- 8001/tcp - High Availability communication

Kea DDNS:
- 53001/udp - DDNS port
- 8000/tcp - Control Agent

You can use this parameter for `docker run` command: \
(Plaese note, that ports have to be bound to an assigned IP addres on host.)
```shell
--publish host_ip:host_port:container_port
```
eg.
```shell
--publish 192.168.50.254:67:67/udp
```
For v6 address you need to use a square bracket like this:
```shell
--publish [2008:db8::1]:547:547/udp
```

## Examples

Here are some example commands to run Kea images. Please modify them for your system, and provide configuration files in volumes.
We recommend looking at working setup in kea-compose.

Creating IPVlan network to use with the containers. (Remove `--ipv6` and v6 subnet if not needed.)
```shell
docker network create --driver ipvlan --ipv6 --subnet 192.168.50.0/24 --subnet 2001:db8:1::/64 --opt parent=enp0s2 ipvlan0
```

Kea DHCP v4 with all volumes:
```shell
docker run --name kea4  \
           --volume ./config/kea:/etc/kea  \
           --volume ./:/var/lib/kea  \
           --net ipvlan0  \
           docker.cloudsmith.io/isc/docker/kea-dhcp4:2.5.2
```

Kea DHCP v6 with all volumes:
```shell
docker run --name kea6  \
           --volume ./config/kea:/etc/kea  \
           --volume ./:/var/lib/kea  \
           --net ipvlan0  \
           docker.cloudsmith.io/isc/docker/kea-dhcp6:2.5.2
```

Kea DDNS with all volumes and ports: \
(Kea DDNS does not need to be run using IPVlan network. It can be bound using default docker bridge) \
(Please note any port colisions with Kea containers. You may need to change port 8000 on host side to eg. 8002)
```shell
docker run  --name kea-ddns  \
            --volume ./config/kea:/etc/kea  \
            --publish 192.168.50.254:53001:53001/udp \
            --publish 192.168.50.254:8000:8000 \
            docker.cloudsmith.io/isc/docker/kea-dhcp-ddns:2.5.2
```


# Using Dockerfiles

Typically, users don't need to build the images themselves. Using existing images built by ISC is usually more convenient. However, in some cases, users may want to tweak some build parameters of the images to adjust them for specific needs. In such a case, the following section explains how to do it.

## Building image

You need to have Docker installed. The image can be built using the following
command:

```shell
cd kea-dhcp4 && docker build --tag kea4 .
```

If a user wants to install a specific Kea version, not the onde defined
in dockerfile build argument `VERSION` is required

```shell
cd kea-dhcp4 && docker build --build-arg VERSION=2.3.8-r20230530063557 --tag kea4 .
```

If a user has access to premium packages, it should be added during the build process:

```shell
cd kea-dhcp4 && docker build --build-arg VERSION=2.3.8-r20230530063557 --build-arg TOKEN=<TOKEN> --tag kea4 .
```

If the provided token grants access to subscribers or enterprise packages, it should be specified:

```shell
cd kea-dhcp4 && docker build --build-arg VERSION=2.3.8-r20230530063557 --build-arg TOKEN=<TOKEN> --build-arg PREMIUM=ENTERPRISE --tag kea4 .
```

This will end up with something like the following:

```shell
Successfully built <image-id>
```

## Preparing Volumes

You probably want to mount the following volumes:

Strictly speaking, you don't need to mount any of them. If you don't, Kea will
run on the defaults provided, but those will almost never work for you. At the
very least, you should mount `/etc/kea` with your own config file that
corresponds to your actual network.

## Running the image

Containers are using a supervisor to run two processes: control agent for exposing Kea
API channel and one kea process (kea-dhcp4, kea-dhcp6 and kea-dhcp-ddns)

To bind container to specific physical (or vlan) interface you need to create "IPVlan" docker network.

To create this network use: (Remove `--ipv6` and v6 subnet if not needed.)
```shell
docker network create --driver ipvlan --ipv6 --subnet <subnet> --opt parent=<host-interface> <ipvlan-network-name>
```

Each container has its default configuration included. This is why it's possible to run it without any additional changes:

```shell
docker run --net <ipvlan_network_name> kea4
```

There are two ways to change Kea configuration. Via command control channel by sending `config-set` command or by overwriting files in docker:

```shell
docker run --volume ./:/etc/kea  \
                --net <ipvlan_network_name> <image-id or tag>
```

or

```shell
docker run --volume ./kea-dhcp4.conf:/etc/kea/kea-dhcp4.conf  \
                --net <ipvlan_network_name> <image-id or tag>
```

By default, containers are exposing `/var/lib/kea` so users can have easy access to leases files. Option `--volume=./:/var/lib/kea` should be added on docker startup:

```shell
docker run --volume ./config/kea:/etc/kea  \
                --volume ./:/var/lib/kea  \
                --net <ipvlan_network_name> <image-id or tag>
```

# Kea configuration

Some settings should be considered when preparing a configuration file for the Kea service.

- Alpine Kea containers use `ethX` interface naming. E.g., `eth0`, `eth1`. Docker is assigning networks alphabetically, starting from `eth0`.
- Control Agent can be configured to listen on all interfaces by setting `"http-host": "0.0.0.0"`.
- Kea-DDNS can be configured to listen on all interfaces by setting `"ip-address": "0.0.0.0"`. (Starting from Kea version 2.5.3). \
This setting should only be used if the DDNS port is not forwarded outside the kea<>ddns network.

# Kea-Compose script

Kea-compose script allows for easy deployment of basic kea-dhcp server. (Including kea-dhcp4, kea-dhcp6, and postgresql lease database)

You need to have IPv6 enabled in docker engine:
Edit `/etc/docker/daemon.json` and add:
```json
{
  "experimental": true,
  "ip6tables": true
}
```
Restart docker service.
(more informations: https://docs.docker.com/config/daemon/ipv6/)

Preparation:
- Edit `.env` file to set your parameters.
- Run `./build_images.sh` to prepare kea images

Running Kea:
- Run `docker compose up` to run all containers

# Other

## Docker issues

There are some issues with using DHCP, and IPv6 in Docker Engine that are good to know.

- Docker does not allow to select order of connecting of the network interfaces. (priority does not work)  \
https://github.com/docker/cli/issues/1372

- IPv6 is an EXPERIMENTAL feature in docker. \
https://docs.docker.com/config/daemon/ipv6/

- IPv6-only networks are not available without heavy workarounds
https://github.com/moby/moby/issues/32850

- The base value for the docker network IPv6 needs a minimum prefix length of /64. This is due to an integer overflow in the Docker daemon. This does not affect DHCP subnet. \
https://github.com/moby/moby/issues/42801

- The difference between the docker network pool length and the pool size can't be larger than 24. Defining an excessive number of subnets causes the daemon to consume all available memory. This does not affect DHCP pool. \
https://github.com/moby/moby/issues/40275

- Docker assignes IP addresses to container network interfaces. We can select the IP, but can not skip this step.

## Support

For information about ISC, Stork, Kea and for purchasing professional technical support from ISC, see our website.
The Development and maintenance of Kea and Stork is funded by your support contracts. The kea-users mailing list
(https://lists.isc.org/mailman/listinfo/kea-users) is a resource for free community support. Please subscribe in
order to post. We would love feedback about how this Docker image is working for you!

## Documentation

Documentation for Kea is available on [ReadTheDocs](https://kea.readthedocs.io).
Further documentation, including many short FAQs is available in [ISC's Knowledgebase](kb.isc.org/).

## Issues

To report a bug, navigate to our project repository. Please try searching for your issue first in case someone else
has already logged it.

## License

Kea and Stork are licensed under the MPL2.0 license.
