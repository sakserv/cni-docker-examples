#!/bin/bash

#
# Vars
#
etcd_version="3.3.9"
etcd_dir="/usr/local/bin/etcd"
primary_ip=$(ip -o -4 addr show dev eth1 | cut -d' ' -f7 | cut -d'/' -f1)

cd $etcd_dir && nohup etcd-v${etcd_version}-linux-amd64/etcd --advertise-client-urls=http://${primary_ip}:2379 --listen-client-urls=http://${primary_ip}:2379 --data-dir=/usr/local/bin/etcd/default.etcd > $etcd_dir/etcd.log &
sleep 10
