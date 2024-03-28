#!/bin/bash

# make network namespace
sudo ip netns add ns1
sudo ip netns add ns2

# make interface(veth(virtual ethernet device))
sudo ip link add ns1-veth0 type veth peer name ns2-veth0

# let namespace use interface
sudo ip link set ns1-veth0 netns ns1
sudo ip link set ns2-veth0 netns ns2

# set ip address
sudo ip netns exec ns1 ip address add 192.0.2.1/24 dev ns1-veth0
sudo ip netns exec ns2 ip address add 192.0.2.2/24 dev ns2-veth0

# check mac address
sudo ip netns exec ns1 ip link show | grep link/ether
sudo ip netns exec ns2 ip link show | grep link/ether

# set mac address
sudo ip netns exec ns1 ip link set dev ns1-veth0 address 00:00:5E:00:53:01
sudo ip netns exec ns2 ip link set dev ns2-veth0 address 00:00:5E:00:53:02

# check mac address
sudo ip netns exec ns1 ip link show | grep link/ether
sudo ip netns exec ns2 ip link show | grep link/ether

# make interface state UP
sudo ip netns exec ns1 ip link set ns1-veth0 up
sudo ip netns exec ns2 ip link set ns2-veth0 up

# check interface state
sudo ip netns exec ns1 ip link show ns1-veth0 | grep state
sudo ip netns exec ns2 ip link show ns2-veth0 | grep state

# ping test
#sudo ip netns exec ns1 ping -c 3 192.0.2.2
#sudo ip netns exec ns2 ping -c 3 192.0.2.1

# check mac address cashe
sudo ip netns exec ns1 ip neigh

# delete mac address cashe
sudo ip netns exec ns1 ip neigh flush all

# tcpdump to check mac
sudo ip netns exec ns1 tcpdump -tnel -i ns1-veth0 icmp or arp &
sudo ip netns exec ns1 ping -c 3 192.0.2.2 > /dev/null 2>&1
sudo kill $!
sleep 1

# iperf test
sudo ip netns exec ns2 iperf3 -s &
sudo ip netns exec ns1 iperf3 -c 192.0.2.2 -t 3
sudo kill $!
sleep 1

# delete all network namespace
sudo ip --all netns delete
