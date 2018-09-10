#!/bin/bash

#
# Vars
#
weave_url="git.io/weave"

#
# Args parsing
#
if [ $# -ne 2 ]; then
  echo "ERROR: Must supply the node ID and IP of the primary node"
  exit 1
fi
node_id="$1"
primary_ip="$2"

echo "##########"
echo "# Node Id: $node_id"
echo "# Primary Node IP: $node_id"
echo "##########"

#
# Install weave
#
curl -L $weave_url -o /usr/local/bin/weave
chmod a+x /usr/local/bin/weave

#
# Create CNI dirs
#
mkdir -p /opt/cni/bin
mkdir -p /etc/cni/net.d

#
# Launch weave
#
if [ "$node_id" = "1" ]; then
  echo "## Starting weave on primary node"
  /usr/local/bin/weave launch
else
  echo "## Starting weave on member node"
  /usr/local/bin/weave launch $primary_ip
fi

#
# Copy scripts
#
echo "## Copying testing scripts"
mkdir -p /scripts
cp /vagrant/*.sh /scripts
chmod -R 755 /scripts

#
# Exit
#
echo "## bootstrap completed successfully"
exit 0
