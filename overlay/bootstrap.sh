#!/bin/bash

#
# Vars
#
zk_image="zookeeper:latest"
our_ip=`/sbin/ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`
docker_conf=/etc/docker/daemon.json
proxy_port=38000

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
echo "# Primary Node IP: $primary_ip"
echo "##########"

#
# Run zk on the first node
#
if [ "$node_id" = "1" ]; then
  echo "## Setting up zk"
  docker run -d --name zk --restart always --net host zookeeper
  sleep 10
fi

#
# Configure docker
#
echo "Configuring docker to use zk"
echo '{
	"cluster-store" : "zk://'${primary_ip}':2181",
	"cluster-advertise" : "'${our_ip}':2376",
	"live-restore" : true,
	"debug" : true
}' > $docker_conf
systemctl restart docker
sleep 10

#
# Create the hadoop overlay network
#
if [ "$node_id" = "1" ]; then
  echo "Creating the hadoop overlay network"
  docker network create -d overlay --subnet 10.101.0.0/16 hadoop
  sleep 10
fi

#
# Start the httpd container
#
echo "Starting the httpd container on `hostname`"
mkdir -p /work
if [ "$node_id" = "1" ]; then
  container_ip="10.101.10.1"
  container_name="httpd-0"
  container_network="hadoop"
elif [ "$node_id" = "2" ]; then
  container_ip="10.101.10.2"
  container_name="httpd-1"
  container_network="hadoop"
fi
echo '<html><header><title>Title</title></header><body>Hello from container '${container_name}'!</body></html>' > /work/index.html.${container_name}
docker run -d --net hadoop --ip $container_ip --name $container_name -v /work/index.html.${container_name}:/var/www/html/index.html centos/httpd-24-centos7:latest /usr/bin/run-httpd


#
# Start the proxy container
#
if [ "$node_id" = "2" ]; then
  echo "Setting up the httpd-proxy"
  container_ip="10.101.10.3"
  container_name="httpd-proxy"
  container_network="hadoop"
  cat << EOF > /work/httpd-proxy.conf
<Proxy balancer://test>
  BalancerMember http://httpd-0.hadoop:8080
  BalancerMember http://httpd-1.hadoop:8080
  ProxySet lbmethod=bytraffic
</Proxy>

ProxyPass "/"  "balancer://test/"
ProxyPassReverse "/"  "balancer://test/"
EOF
  docker run -d --net hadoop -p ${proxy_port}:8080 --ip $container_ip --name $container_name -v /work/httpd-proxy.conf:/etc/httpd/conf.d/httpd-proxy.conf centos/httpd-24-centos7:latest /usr/bin/run-httpd
  echo "Open your browser and access the httpd proxy container on http://${our_ip}:${proxy_port}"
fi

exit 0
