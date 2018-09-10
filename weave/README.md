Running Weave CNI with Docker
------------------------------

* Start two VMs
```
cd weave && vagrant up
```

* Once the boot is complete, weave will be running
```
root@weave-01:~# docker ps -a
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS               NAMES
288f58d30214        weaveworks/weave:2.4.0       "/home/weave/weaver …"   6 minutes ago       Up 6 minutes                            weave
3fe6cb701f9a        weaveworks/weaveexec:2.4.0   "data-only"              6 minutes ago       Created                                 weavevolumes-2.4.0
d8d8fcf9343e        weaveworks/weavedb:latest    "data-only"              6 minutes ago       Created                                 weavedb
```

* Start a net container, invoke the weave CNI plugin, and attach an application container
```
root@weave-01:~# /scripts/start_weave_container.sh weavetest
##########
# container name: weavetest
# net container name: weavetest_net
##########
## Launching the net container
0a85021807141bf0c3af11c221a136665e0f31c2fd642bc7baa50ddb1417da70
## Calling weave CNI plugin (logging stderr to /tmp/cni.weavetest)
{
    "ip4": {
        "ip": "10.32.0.3/12",
        "gateway": "10.32.0.2"
    },
    "dns": {}
}## Starting container weavetest attached to net container weavetest_net
528e344729f713783282b338a286065581fd96c4e11e185b5772836ee319e8ef
```

* Clean up the container and network, invoking the CNI delete action
```
root@weave-01:~# /scripts/remove_weave_container.sh weavetest
##########
# container name: weavetest
# net container name: weavetest_net
##########
## Removing container weavetest attached to net container weavetest_net
weavetest
weavetest
## Calling delete action on the weave CNI plugin (logging stderr to /tmp/cni.weavetest)
## Deleting net container weavetest_net
weavetest_net
weavetest_net
```
