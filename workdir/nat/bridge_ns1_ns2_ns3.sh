#!/bin/bash

# make network namespace
sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add bridge

# make interface(veth(virtual ethernet device))
sudo ip link add ns1-veth0 type veth peer name ns1-br0
sudo ip link add ns2-veth0 type veth peer name ns2-br0
sudo ip link add gw-veth0 type veth peer name gw-br0

# let namespace use interface
sudo ip link set ns1-veth0 netns ns1
sudo ip link set ns2-veth0 netns ns2
sudo ip link set ns1-br0 netns bridge
sudo ip link set ns2-br0 netns bridge
sudo ip link set gw-br0 netns bridge

# set ip address
sudo ip netns exec ns1 ip address add 192.0.2.1/24 dev ns1-veth0
sudo ip netns exec ns2 ip address add 192.0.2.2/24 dev ns2-veth0
sudo ip address add 192.0.2.254/24 dev gw-veth0

# set mac address
sudo ip netns exec ns1 ip link set dev ns1-veth0 address 00:00:5E:00:53:01
sudo ip netns exec ns2 ip link set dev ns2-veth0 address 00:00:5E:00:53:02

# make bridge
sudo ip netns exec bridge ip link add dev br0 type bridge


sudo sysctl net.ipv4.ip_forward=1


# make interface state UP
sudo ip netns exec ns1 ip link set ns1-veth0 up
sudo ip netns exec ns2 ip link set ns2-veth0 up
sudo ip link set gw-veth0 up
sudo ip netns exec bridge ip link set ns1-br0 up
sudo ip netns exec bridge ip link set ns2-br0 up
sudo ip netns exec bridge ip link set gw-br0 up
sudo ip netns exec bridge ip link set br0 up

# set default gw
sudo ip netns exec ns1 ip route add default via 192.0.2.254
sudo ip netns exec ns2 ip route add default via 192.0.2.254

# connect veth interface to bridge
sudo ip netns exec bridge ip link set ns1-br0 master br0
sudo ip netns exec bridge ip link set ns2-br0 master br0
sudo ip netns exec bridge ip link set gw-br0 master br0

# check bridge kernel security
lsmod | grep br_netfilter
# 2 way to be able to connect
# 1. disable to bridge netfilter
#sudo sysctl -w net.bridge.bridge-nf-call-iptables=0
# 2. let iptables connect
sudo ip netns exec bridge iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
sudo ip netns exec bridge iptables -nvL --line-number
sudo iptables -t filter -F
sudo iptables -P FORWARD ACCEPT
sudo iptables -t nat -F
sudo iptables -t nat -L
sudo iptables -t nat \
  -A POSTROUTING \
  -o wlan0 \
  -s 192.0.2.0/24 \
  -j MASQUERADE
#sudo iptables -t nat \
#  -A POSTROUTING \
#  -o eth0 \
#  -j SNAT \
#  --to-source 192.0.2.254

#sudo iptables -A INPUT -p icmp -j ACCEPT
#sudo iptables -A FORWARD -p icmp -j ACCEPT

sudo iptables -t nat -L




#sudo tcpdump -tnl -i wlan0 icmp &
#sleep 1

# ping test(to router)
#sudo ip netns exec ns1 ping -c 3 192.0.2.254
#sudo ip netns exec ns1 ping -c 3 8.8.8.8
#sudo ip netns exec ns1 ping -c 3 192.0.2.3
#sudo ip netns exec ns1 ping -c 3 192.168.10.160

#jobs -l | awk -F' ' '{print$2}' | xargs sudo kill

# check mac address table
sudo ip netns exec bridge bridge fdb show br br0 | grep -i 00:00:5e

# delete ns
#sudo ip --all netns delete
