Running Flannel CNI with Docker
------------------------------

* Start two VMs
```
cd flannel && vagrant up
```

* Once the boot is complete, etcd and flanneld will be running
```
root@flannel-01:~# docker ps -a
CONTAINER ID        IMAGE                                  COMMAND                  CREATED             STATUS              PORTS               NAMES
e8638f3e907f        quay.io/coreos/flannel:v0.10.0-amd64   "/opt/bin/flanneld -…"   56 seconds ago      Up 55 seconds                           flanneld
```

* Start a net container, invoke the flannel CNI plugin, and attach an application container
```
root@flannel-01:~# /vagrant/start_flannel_container.sh flanneltest
##########
# container name: flanneltest
# net container name: flanneltest_net
##########
## Launching the net container
e73e73a7dd6a8f98751b8c5fabff55a40897de6ba19430f4653f231f8d16d731
## Calling flannel CNI plugin (logging stderr to /tmp/cni.flanneltest)
{
    "cniVersion": "0.2.0",
    "ip4": {
        "ip": "10.5.37.2/24",
        "gateway": "10.5.37.1",
        "routes": [
            {
                "dst": "10.5.0.0/16",
                "gw": "10.5.37.1"
            }
        ]
    },
    "dns": {}
}
## Starting container flanneltest attached to net container flanneltest_net
7041e1dab31083ef8aa9958b62474565b9d8758848f111242d4eb75491537843
```

* Clean up the container and network, invoking the CNI delete action
```
root@flannel-01:~# /vagrant/remove_flannel_container.sh flanneltest
##########
# container name: flanneltest
# net container name: flanneltest_net
##########
## Removing container flanneltest attached to net container flanneltest_net
flanneltest
flanneltest
## Calling delete action on the flannel CNI plugin (logging stderr to /tmp/cni.flanneltest)
## Deleting net container flanneltest_net
flanneltest_net
flanneltest_net
```
