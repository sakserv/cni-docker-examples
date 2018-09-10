#!/bin/bash

#
# Vars
#
eth1_ip=$(ip -o -4 addr show dev eth1 | cut -d' ' -f7 | cut -d'/' -f1)
etcd_version="3.3.9"
etcd_url="https://github.com/coreos/etcd/releases/download/v${etcd_version}/etcd-v${etcd_version}-linux-amd64.tar.gz"
etcd_dir="/usr/local/bin/etcd"
cni_plugin_url="https://github.com/containernetworking/plugins/releases/download/v0.7.1/cni-plugins-amd64-v0.7.1.tgz"

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
# Install etcd on the first node
#
if [ "$node_id" = "1" ]; then
  echo "## Setting up etcd"
  mkdir $etcd_dir
  curl -L --silent $etcd_url -o $etcd_dir/etcd-v${etcd_version}-linux-amd64.tar.gz 
  cd $etcd_dir && tar xzvf etcd-v${etcd_version}-linux-amd64.tar.gz
  cd $etcd_dir && nohup etcd-v${etcd_version}-linux-amd64/etcd --advertise-client-urls=http://${primary_ip}:2379 --listen-client-urls=http://${primary_ip}:2379 --data-dir=/usr/local/bin/etcd/default.etcd > $etcd_dir/etcd.log &
  sleep 10
fi

#
# Setup environment
#
echo "## Setting environment variables"
echo 'export ETCD_ENDPOINTS="http://'${primary_ip}':2379"' >> /etc/profile

#
# Setup flannel CNI config
#
echo "## Configuring CNI for flannel"
mkdir -p /etc/cni/net.d
cat > /etc/cni/net.d/10-flannel.conf << EOF
{
	"name": "flannelnet",
	"type": "flannel"
}
EOF

#
# Install the flannel plugins
#
mkdir -p /opt/cni/bin
wget $cni_plugin_url -O /tmp/cni-plugins.tgz
cd /tmp && tar -xzvf /tmp/cni-plugins.tgz -C /opt/cni/bin ./flannel
cd /tmp && tar -xzvf /tmp/cni-plugins.tgz -C /opt/cni/bin ./host-local
cd /tmp && tar -xzvf /tmp/cni-plugins.tgz -C /opt/cni/bin ./bridge

#
# Start flannel
#
docker run --name=flanneld --net=host --privileged -d -v /run/flannel:/run/flannel quay.io/coreos/flannel:v0.10.0-amd64 --public-ip="$eth1_ip" --etcd-endpoints=http://$primary_ip:2379 --iface="eth1"

#
# Configure flannel subnet
#
if [ "$node_id" = "1" ]; then
  docker run --rm --net=host quay.io/coreos/etcd etcdctl --endpoint=http://${primary_ip}:2379 set /coreos.com/network/config '{ "Network": "10.5.0.0/16", "Backend": {"Type": "vxlan"}}'
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
