#!/bin/bash

# make network namespace
sudo ip netns add lan
sudo ip netns add wan
sudo ip netns add router

# make interface(veth(virtual ethernet device))
sudo ip link add lan-veth0 type veth peer name gw-veth0
sudo ip link add wan-veth0 type veth peer name gw-veth1

# let namespace use interface
sudo ip link set lan-veth0 netns lan
sudo ip link set gw-veth0 netns router
sudo ip link set wan-veth0 netns wan
sudo ip link set gw-veth1 netns router

# set ip address
sudo ip netns exec lan ip address add 192.0.2.1/24 dev lan-veth0
sudo ip netns exec router ip address add 192.0.2.254/24 dev gw-veth0
sudo ip netns exec wan ip address add 203.0.113.1/24 dev wan-veth0
sudo ip netns exec router ip address add 203.0.113.254/24 dev gw-veth1

# set config of router
sudo ip netns exec router sysctl net.ipv4.ip_forward=1

# make interface state UP
sudo ip netns exec lan ip link set lan-veth0 up
sudo ip netns exec router ip link set gw-veth0 up
sudo ip netns exec wan ip link set wan-veth0 up
sudo ip netns exec router ip link set gw-veth1 up

# set default gw(note:after interface state up)
sudo ip netns exec lan ip route add default via 192.0.2.254
#sudo ip netns exec wan ip route add default via 203.0.113.254

# check NAT configuration before additional
echo '/* before NAT config */'
sudo ip netns exec router iptables -t nat -L

# add src NAT rule
sudo ip netns exec router iptables -t nat \
  -A POSTROUTING \
  -s 192.0.2.0/24 \
  -o gw-veth1 \
  -j MASQUERADE

# check NAT configuration after additional
echo '/* after NAT config */'
sudo ip netns exec router iptables -t nat -L


# check routing table
#sudo ip netns exec lan ip route show
#sudo ip netns exec wan ip route show

# tcpdump for check ip masquerade
#sudo ip netns exec lan tcpdump -tnl -i lan-veth0 icmp &
sudo ip netns exec wan tcpdump -tnl -i wan-veth0 icmp &
sleep 1

# ping test(to dest)
sudo ip netns exec lan ping -c 3 203.0.113.1 > /dev/null 2>&1
#sudo ip netns exec wan ping -c 3 192.0.2.1

# kill task
jobs -l | awk -F' ' '{print $2}' | xargs sudo kill

# delete ns
sudo ip --all netns delete
