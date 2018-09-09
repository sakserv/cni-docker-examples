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
# Main
#
echo "##########"
echo "# container name: $CONTAINER_NAME"
echo "# net container name: ${CONTAINER_NAME}_net"
echo "##########"

# Launch the netcontainer
echo "## Launching the net container"
docker run -d --net=none --name=${CONTAINER_NAME}_net gcr.io/google_containers/pause || exit 1

# Configure the netns
echo "## Calling flannel CNI plugin (logging stderr to /tmp/cni.${CONTAINER_NAME})"
CNI_COMMAND=ADD CNI_CONTAINERID=${CONTAINER_NAME} CNI_NETNS=$(docker inspect --format '{{.NetworkSettings.SandboxKey}}' ${CONTAINER_NAME}_net) CNI_IFNAME=eth10 CNI_PATH=/opt/cni /opt/cni/flannel 2>>/tmp/cni.${CONTAINER_NAME} </etc/cni/net.d/11-flannel.conf || exit 1

# Launch the app container
echo "## Starting container ${CONTAINER_NAME} attached to net container ${CONTAINER_NAME}_net"
docker run -d --net=container:${CONTAINER_NAME}_net --name=${CONTAINER_NAME} alpine:latest sleep 1000000 || exit 1
