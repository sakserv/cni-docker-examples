#!/bin/bash

#
# Vars
#
etcd_version="3.3.9"
etcd_url="https://github.com/coreos/etcd/releases/download/v${etcd_version}/etcd-v${etcd_version}-linux-amd64.tar.gz"
etcd_dir="/usr/local/bin/etcd"
calicoctl_url="https://github.com/projectcalico/calicoctl/releases/download/v3.2.0/calicoctl"

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
# Download calicoctl
#
echo "## Downloading calicoctl"
curl -L --silent ${calicoctl_url} -o /usr/local/bin/calicoctl
chmod +x /usr/local/bin/calicoctl

#
# Setup environment
#
echo "## Setting environment variables"
echo 'export ETCD_ENDPOINTS="http://'${primary_ip}':2379"' >> /etc/profile

#
# Start the calico/node container
#
echo "## Starting the calico/node container"
docker run --net=host --privileged --name=calico-node -d -e NODENAME=`hostname -f | cut -d. -f1` -e CALICO_NETWORKING_BACKEND=bird -e CALICO_LIBNETWORK_ENABLED=false -e ETCD_ENDPOINTS=http://${primary_ip}:2379 -e WAIT_FOR_DATASTORE=true -e DATASTORE_TYPE=etcdv3 -v /var/log/calico:/var/log/calico -v /var/run/calico:/var/run/calico -v /var/lib/calico:/var/lib/calico -v /lib/modules:/lib/modules -v /run:/run quay.io/calico/node:release-v3.2

#
# Setup calico CNI config
#
echo "## Configuring CNI for calico"
mkdir -p /etc/cni/net.d
cat > /etc/cni/net.d/10-calico.conf << EOF
{
    "name": "calico",
    "type": "calico",
    "log_level": "INFO",
    "etcd_endpoints": "http://${primary_ip}:2379",
    "ipam": {
        "type": "calico-ipam"
    }
}
EOF

#
# Install the CNI calico plugins
#
echo "## Installing the calico CNI plugins"
mkdir /opt/cni
wget https://github.com/projectcalico/cni-plugin/releases/download/v3.2.0/calico -O /opt/cni/calico
wget https://github.com/projectcalico/cni-plugin/releases/download/v3.2.0/calico-ipam -O /opt/cni/calico-ipam
chmod 755 /opt/cni/calico*

#
# Copy scripts
#
echo "## Copying testing scripts"
mkdir /scripts
cp /vagrant/*.sh /scripts
chmod -R 755 /scripts

#
# Exit
#
echo "## bootstrap completed successfully"
exit 0
