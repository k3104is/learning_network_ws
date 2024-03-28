#!/bin/bash

# tcpdump
sudo tcpdump -tnl -i any "udp and port 53" &
sleep 1

# resolve domain name using Google public DNS service
dig +short @8.8.8.8 example.org A
sleep 1

# kill task
sudo kill $!
