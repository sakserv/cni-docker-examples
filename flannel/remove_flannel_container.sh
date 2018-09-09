#!/bin/bash

#
# Parse cmdline
#
if [ $# -ne 1 ]; then
  echo "ERROR: Must supply the name of the container to remove"
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

# Remove the app container
echo "## Removing container ${CONTAINER_NAME} attached to net container ${CONTAINER_NAME}_net"
docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME

# Call delete on the CNI plugin
echo "## Calling delete action on the flannel CNI plugin (logging stderr to /tmp/cni.${CONTAINER_NAME})"
CNI_COMMAND=DEL CNI_CONTAINERID=${CONTAINER_NAME} CNI_NETNS=$(docker inspect --format '{{.NetworkSettings.SandboxKey}}' ${CONTAINER_NAME}_net) CNI_IFNAME=eth10 CNI_PATH=/opt/cni /opt/cni/flannel 2>>/tmp/cni.${CONTAINER_NAME} </etc/cni/net.d/11-flannel.conf || exit 1

# Delete the net container the app container
echo "## Deleting net container ${CONTAINER_NAME}_net"
docker stop ${CONTAINER_NAME}_net && docker rm ${CONTAINER_NAME}_net
