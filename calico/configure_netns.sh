#!/bin/bash

#
# Parse cmdline
#
if [ $# -ne 1 ]; then
  echo "ERROR: Must supply the name of the container to create"
  exit 1
fi
CONTAINER_NAME="$1"

#
# Vars
#
NET_CONTAINER_NAME="${CONTAINER_NAME}"
if ! echo $CONTAINER_NAME | grep -q "_net$"; then
  NET_CONTAINER_NAME="${CONTAINER_NAME}_net"
fi

#
# Main
#
echo "##########"
echo "# container name: $CONTAINER_NAME"
echo "# net container name: $NET_CONTAINER_NAME"
echo "##########"

# Setup the netns
echo "## Configuring the netns"
mkdir -p /var/run/netns
netns=$(docker inspect --format '{{.NetworkSettings.SandboxKey}}' $NET_CONTAINER_NAME)
pid=$(docker inspect -f '{{.State.Pid}}' $NET_CONTAINER_NAME)
ln -sfT /proc/$pid/ns/net /var/run/netns/$NET_CONTAINER_NAME
