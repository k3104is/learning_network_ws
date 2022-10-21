#!/bin/bash

# cmd
EXEC_NS1_CMD="sudo ip netns exec ns1"
EXEC_NS2_CMD="sudo ip netns exec ns2"

# set key
MACSEC1_KEY='327235753878214125442A472D4B6150'
MACSEC2_KEY='7A25432A462D4A614E645267556B586E'

# make namespace
sudo ip netns add ns1
sudo ip netns add ns2

# make interface
sudo ip link add ns1-veth0 type veth peer name ns2-veth0

# check mac address
NS1_MAC_ADDR=$(cat /sys/class/net/ns1-veth0/address)
NS2_MAC_ADDR=$(cat /sys/class/net/ns2-veth0/address)

# connect interface to namespace
sudo ip link set ns1-veth0 netns ns1
sudo ip link set ns2-veth0 netns ns2

$EXEC_NS1_CMD ip link add link ns1-veth0 macsec1 type macsec encrypt on
$EXEC_NS2_CMD ip link add link ns2-veth0 macsec2 type macsec encrypt on

$EXEC_NS1_CMD ip macsec add macsec1 rx port 1 address ${NS2_MAC_ADDR}
$EXEC_NS1_CMD ip macsec add macsec1 tx sa 0 pn 1 on key 00 ${MACSEC1_KEY}
$EXEC_NS1_CMD ip macsec add macsec1 rx port 1 address ${NS2_MAC_ADDR} sa 0 pn 1 on key 01 ${MACSEC2_KEY}


$EXEC_NS2_CMD ip macsec add macsec2 rx port 1 address ${NS1_MAC_ADDR}
$EXEC_NS2_CMD ip macsec add macsec2 tx sa 0 pn 1 on key 01 ${MACSEC2_KEY}
$EXEC_NS2_CMD ip macsec add macsec2 rx port 1 address ${NS1_MAC_ADDR} sa 0 pn 1 on key 00 ${MACSEC1_KEY}

# set ip addr
$EXEC_NS1_CMD ip addr add dev ns1-veth0 192.0.0.1/24
$EXEC_NS1_CMD ip link set ns1-veth0 up
$EXEC_NS1_CMD ip link set macsec1 up

$EXEC_NS2_CMD ip addr add dev ns2-veth0 192.0.0.2/24
$EXEC_NS2_CMD ip link set ns2-veth0 up
$EXEC_NS2_CMD ip link set macsec2 up

$EXEC_NS2_CMD tcpdump -i ns2-veth0 -tnlA -w - > macsec.pcap &
# $EXEC_NS2_CMD tcpdump -i macsec2 -tnlA -w - > macsec.pcap &
$EXEC_NS2_CMD ncat -lnv 54321 &
sleep 1
echo 'Hello World' | $EXEC_NS1_CMD ncat 192.0.0.2 54321 &
sleep 2

jobs -l | awk -F' ' '{print $2}' | xargs sudo kill -9

sudo ip --all netns delete
