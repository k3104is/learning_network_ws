#! /bin/bash
#
#    namespace                                  namespace
#    mac_sec_ns_0           mac_sec_br          mac_sec_ns_1
#                   +-----------+-----------+
#    mac_sec_0_0----|mac_sec_0_1|mac_sec_0_1|----mac_sec_1_0
#                   +-----------+-----------+
#

sudo ip link add dev mac_sec_if_0_0 type veth peer name mac_sec_if_0_1
sudo ip link add dev mac_sec_if_1_0 type veth peer name mac_sec_if_1_1

mac_sec_if_0_0_mac_addr=$(cat /sys/class/net/mac_sec_if_0_0/address)
mac_sec_if_1_0_mac_addr=$(cat /sys/class/net/mac_sec_if_1_0/address)

mac_sec_if_0_0_key='327235753878214125442A472D4B6150'
mac_sec_if_1_0_key='7A25432A462D4A614E645267556B586E'

sudo ip link add dev mac_sec_br_0 type bridge

sudo ip link set dev mac_sec_if_0_1 master mac_sec_br_0
sudo ip link set dev mac_sec_if_1_1 master mac_sec_br_0

sudo ip netns add mac_sec_ns_0
sudo ip netns add mac_sec_ns_1

sudo ip link set dev mac_sec_if_0_0 netns mac_sec_ns_0
sudo ip link set dev mac_sec_if_1_0 netns mac_sec_ns_1


sudo ip netns exec mac_sec_ns_0 ip link add link mac_sec_if_0_0 mac_sec_0 type macsec encrypt on
sudo ip netns exec mac_sec_ns_1 ip link add link mac_sec_if_1_0 mac_sec_1 type macsec encrypt on

sudo iptables -I FORWARD -o mac_sec_br_0 -j ACCEPT
sudo ip link set mac_sec_br_0 up

# ip netns exec mac_sec_ns_1 ip macsec show

sudo ip netns exec mac_sec_ns_0 ip macsec add mac_sec_0 rx port 1 address ${mac_sec_if_1_0_mac_addr}
sudo ip netns exec mac_sec_ns_0 ip macsec add mac_sec_0 tx sa 0 pn 1 on key 00 ${mac_sec_if_0_0_key}
sudo ip netns exec mac_sec_ns_0 ip macsec add mac_sec_0 rx port 1 address ${mac_sec_if_1_0_mac_addr} sa 0 pn 1 on key 01 ${mac_sec_if_1_0_key}

sudo ip netns exec mac_sec_ns_1 ip macsec add mac_sec_1 rx port 1 address ${mac_sec_if_0_0_mac_addr}
sudo ip netns exec mac_sec_ns_1 ip macsec add mac_sec_1 tx sa 0 pn 1 on key 01 ${mac_sec_if_1_0_key}
sudo ip netns exec mac_sec_ns_1 ip macsec add mac_sec_1 rx port 1 address ${mac_sec_if_0_0_mac_addr} sa 0 pn 1 on key 00 ${mac_sec_if_0_0_key}

sudo ip netns exec mac_sec_ns_0 ip addr add dev mac_sec_if_0_0 10.1.1.1/24
sudo ip netns exec mac_sec_ns_0 ip link set dev mac_sec_if_0_0 up
sudo ip netns exec mac_sec_ns_0 ip addr add dev mac_sec_0 192.168.1.1/24
sudo ip netns exec mac_sec_ns_0 ip link set dev mac_sec_0 up
sudo ip link set dev mac_sec_if_0_1 up


sudo ip netns exec mac_sec_ns_1 ip addr add dev mac_sec_if_1_0 10.1.1.2/24
sudo ip netns exec mac_sec_ns_1 ip link set dev mac_sec_if_1_0 up
sudo ip netns exec mac_sec_ns_1 ip addr add dev mac_sec_1 192.168.1.2/24
sudo ip netns exec mac_sec_ns_1 ip link set dev mac_sec_1 up
sudo ip link set dev mac_sec_if_1_1 up

echo '**************************'
echo '*  CTRL+C to exit ping   *'
echo '* and remove all devices *'
echo '**************************'

# ping to 10.1.1.2 uses unencrypted path
#ip netns exec mac_sec_ns_0 ping 10.1.1.2

# ping to 192.168.1.2 is encrypted using mac-sec
sudo ip netns exec mac_sec_ns_0 ping 192.168.1.2

#########################################
echo "destroy ..."

sudo ip netns del mac_sec_ns_0
sudo ip netns del mac_sec_ns_1

sudo ip link del mac_sec_br_0
