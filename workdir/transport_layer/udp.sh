#!/bin/bash

# launch udp server
ncat -ulnv 127.0.0.1 54321 > /dev/null 2>&1 &
sleep 1

# tcpdump to check communication
sudo tcpdump -i lo -tnlA "udp and port 54321" -w - > udp.cap &
sleep 1

# launch udp client
echo "Hello, World!" | ncat -u 127.0.0.1 54321 &
sleep 1

# delete task
kill %1 > /dev/null 2>&1
kill %3 > /dev/null 2>&1
jobs > /dev/null 2>&1
jobs -l | awk -F' ' '{print $2}' | xargs sudo kill > /dev/null 2>&1
sleep 1
jobs  > /dev/null 2>&1
