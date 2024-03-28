#!/bin/bash

# make network namespace
sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add router

# make interface(veth(virtual ethernet device))
sudo ip link add ns1-veth0 type veth peer name gw-veth0
sudo ip link add ns2-veth1 type veth peer name gw-veth1

# let namespace use interface
sudo ip link set ns1-veth0 netns ns1
sudo ip link set gw-veth0 netns router
sudo ip link set ns2-veth1 netns ns2
sudo ip link set gw-veth1 netns router

# set ip address
sudo ip netns exec ns1 ip address add 192.0.2.1/24 dev ns1-veth0
sudo ip netns exec router ip address add 192.0.2.254/24 dev gw-veth0
sudo ip netns exec ns2 ip address add 198.51.100.1/24 dev ns2-veth1
sudo ip netns exec router ip address add 198.51.100.254/24 dev gw-veth1

# set config of router
sudo ip netns exec router sysctl net.ipv4.ip_forward=1

# make interface state UP
sudo ip netns exec ns1 ip link set ns1-veth0 up
sudo ip netns exec router ip link set gw-veth0 up
sudo ip netns exec ns2 ip link set ns2-veth1 up
sudo ip netns exec router ip link set gw-veth1 up

# set default gw(note:after interface state up)
sudo ip netns exec ns1 ip route add default via 192.0.2.254
sudo ip netns exec ns2 ip route add default via 198.51.100.254

# check interface state
sudo ip netns exec ns1 ip link show ns1-veth0 | grep state
sudo ip netns exec ns2 ip link show ns2-veth1 | grep state
sudo ip netns exec router ip link show gw-veth0 | grep state
sudo ip netns exec router ip link show gw-veth1 | grep state

# check routing table
sudo ip netns exec ns1 ip route show
sudo ip netns exec ns2 ip route show

# ping test(to router)
#sudo ip netns exec ns1 ping -c 3 192.0.2.254
#sudo ip netns exec ns2 ping -c 3 198.51.100.254

# ping test(to dest)
#sudo ip netns exec ns1 ping -c 3 198.51.100.1
#sudo ip netns exec ns2 ping -c 3 192.0.2.1

# delete mac address cashe

# delete ns
sudo ip --all netns delete
