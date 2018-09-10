Running Calico CNI with Docker
------------------------------

* Start two VMs
```
cd calico && vagrant up
```

* Once the boot is complete, etcd and calico/node will be running
```
root@calico-01:~# docker ps -a
CONTAINER ID        IMAGE                              COMMAND             CREATED             STATUS              PORTS               NAMES
58fb0c71e2f9        quay.io/calico/node:release-v3.2   "start_runit"       5 minutes ago       Up 5 minutes                            calico-node
```

* Start a net container, invoke the calico CNI plugin, and attach an application container
```
root@calico-01:~# /scripts/start_calico_container.sh calicotest
##########
# container name: calicotest
# net container name: calicotest_net
##########
## Launching the net container
038cffd2681d9237f4c356c0bfa83ae7b2d4db3b211b95824b0c503957a0c2e9
## Calling calico CNI plugin (logging stderr to /tmp/cni.calicotest
{
    "cniVersion": "0.2.0",
    "ip4": {
        "ip": "192.168.84.192/32"
    },
    "dns": {}
}
608344ea45b059d423778b61a12e49c2e5f840516022d0b83c043d58f4b8db00
```

* Clean up the container and network, invoking the CNI delete action
```
root@calico-01:~# /scripts/remove_calico_container.sh calicotest
##########
# container name: calicotest
# net container name: calicotest_net
##########
## Removing container calicotest attached to net container calicotest_net
calicotest
calicotest
## Calling delete action on the calico CNI plugin (logging stderr to /tmp/cni.calicotest
## Deleting net container calicotest_net
calicotest_net
calicotest_net
```
