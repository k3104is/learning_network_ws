#!/bin/bash

# reference
# https://costiser.ro/2016/08/01/macsec-implementation-on-linux/#google_vignette

# define
EXEC_NS1_CMD="sudo ip netns exec ns1"
EXEC_NS2_CMD="sudo ip netns exec ns2"
MACSEC1_KEY='327235753878214125442A472D4B6150'
MACSEC2_KEY='7A25432A462D4A614E645267556B586E'
# configuration
SLEEP_TIME=3
ENCRYPT_ENABLE="on"

# create namespace
sudo ip netns add ns1
sudo ip netns add ns2

# create interface
sudo ip link add ns1-veth0 type veth peer name ns2-veth0

# load mac address
NS1_MAC_ADDR=$(cat /sys/class/net/ns1-veth0/address)
NS2_MAC_ADDR=$(cat /sys/class/net/ns2-veth0/address)

# connect interface to namespace
sudo ip link set ns1-veth0 netns ns1
sudo ip link set ns2-veth0 netns ns2

# create the macsec interface
$EXEC_NS1_CMD ip link add link ns1-veth0 macsec1 type macsec encrypt ${ENCRYPT_ENABLE}
$EXEC_NS2_CMD ip link add link ns2-veth0 macsec2 type macsec encrypt ${ENCRYPT_ENABLE}

# configure the tx/rx
$EXEC_NS1_CMD ip macsec add macsec1 tx sa 0 pn 100 on key 01 ${MACSEC1_KEY}
$EXEC_NS1_CMD ip macsec add macsec1 rx port 1 address ${NS2_MAC_ADDR}
$EXEC_NS1_CMD ip macsec add macsec1 rx port 1 address ${NS2_MAC_ADDR} sa 0 pn 100 on key 02 ${MACSEC2_KEY}

$EXEC_NS2_CMD ip macsec add macsec2 tx sa 0 pn 100 on key 02 ${MACSEC2_KEY}
$EXEC_NS2_CMD ip macsec add macsec2 rx port 1 address ${NS1_MAC_ADDR}
$EXEC_NS2_CMD ip macsec add macsec2 rx port 1 address ${NS1_MAC_ADDR} sa 0 pn 100 on key 01 ${MACSEC1_KEY}

# configure ip addr
$EXEC_NS1_CMD ip link set ns1-veth0 up
$EXEC_NS1_CMD ip link set macsec1 up
$EXEC_NS1_CMD ip addr add dev macsec1 192.0.0.1/24

$EXEC_NS2_CMD ip link set ns2-veth0 up
$EXEC_NS2_CMD ip link set macsec2 up
$EXEC_NS2_CMD ip addr add dev macsec2 192.0.0.2/24

# check interface
$EXEC_NS1_CMD ip macsec show
$EXEC_NS2_CMD ip macsec show

# verification (connectivity test)
$EXEC_NS2_CMD tcpdump -i ns2-veth0 -tnlA -w - > macsec_enc_${ENCRYPT_ENABLE}.pcap &
sleep 1
$EXEC_NS2_CMD ncat -lnv 54321 &
sleep ${SLEEP_TIME}
echo 'Hello World' | $EXEC_NS1_CMD ncat 192.0.0.2 54321 &
sleep ${SLEEP_TIME}

# kill background processes
jobs -l | awk -F' ' '{print $2}' | xargs sudo kill -9

# clear namespace
sudo ip --all netns delete
