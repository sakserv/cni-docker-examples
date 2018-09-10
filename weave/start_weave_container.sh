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
cni_log="/tmp/cni.weave.start.eth10.${CONTAINER_NAME}"
echo "## Calling weave CNI plugin (logging stderr to $cni_log)"
CNI_COMMAND=ADD CNI_CONTAINERID=${CONTAINER_NAME} CNI_NETNS=$(docker inspect --format '{{.NetworkSettings.SandboxKey}}' ${CONTAINER_NAME}_net) CNI_IFNAME=eth10 CNI_PATH=/opt/cni/bin /opt/cni/bin/weave-net 2>>$cni_log </etc/cni/net.d/10-weave.conf || exit 1

# Launch the app container
echo "## Starting container ${CONTAINER_NAME} attached to net container ${CONTAINER_NAME}_net"
docker run -d --net=container:${CONTAINER_NAME}_net --name=${CONTAINER_NAME} alpine:latest sleep 1000000 || exit 1
