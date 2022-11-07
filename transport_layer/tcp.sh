#!/bin/bash

# launch tcp server
ncat -lnv 127.0.0.1 54321 > /dev/null 2>&1 &
sleep 1

# tcpdump to check communication
sudo tcpdump -i lo -tnlA "tcp and port 54321" -w - > tcp.cap &
sleep 1

# launch udp client
echo "Hello, World!" | ncat 127.0.0.1 54321 &
sleep 1

# delete task
jobs -l | awk -F' ' '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
sleep 1
