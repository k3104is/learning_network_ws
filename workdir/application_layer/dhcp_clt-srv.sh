#!/bin/bash

# make network namespace
sudo ip netns add client
sudo ip netns add server

# make interface(veth(virtual ethernet device))
sudo ip link add c-veth0 type veth peer name s-veth0

# let namespace use interface
sudo ip link set c-veth0 netns client
sudo ip link set s-veth0 netns server

# set ip address
sudo ip netns exec server ip address add 192.0.2.254/24 dev s-veth0

# make interface state UP
sudo ip netns exec client ip link set c-veth0 up
sudo ip netns exec server ip link set s-veth0 up

# check interface state
sudo ip netns exec client ip link show c-veth0 | grep state
sudo ip netns exec server ip link show s-veth0 | grep state

# launch DHCP server(192.0.2.100-200)
sudo ip netns exec server dnsmasq \
--dhcp-range=192.0.2.100,192.0.2.200,255.255.255.0 \
--interface=s-veth0 \
--port 0 \
--no-resolv \
--no-daemon &

# run DHCP client
sudo ip netns exec client dhclient -d c-veth0 &
sleep 25

# check IP address of veth interface
sudo ip netns exec client ip address show | grep inet

# check routing table
sudo ip netns exec client ip route show

# kill task
jobs -l | awk -F' ' '{print $2}' | xargs sudo kill 

# delete all network namespace
sudo ip --all netns delete
