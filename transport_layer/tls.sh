#!/bin/bash

# make self certification
#openssl req -new -x509 -keyout test-key.pem -out test-cert.pem
openssl req -new -x509 \
  -keyout test-key.pem \
  -out test-cert.pem \
  -passout pass:test \
  -subj "/C=JP/ST=Nagoya/O=myhome/CN=localhost"
sleep 1

# launch tcp server
#echo "test" | ncat -lnv 127.0.0.1 54321 --ssl --ssl-cert test-cert.pem --ssl-key test-key.pem  > /dev/null 2>&1 &

expect -c "
  set timeout 3
  spawn ncat -lnv 127.0.0.1 54321 --ssl --ssl-cert test-cert.pem --ssl-key test-key.pem
  expect \"Enter PEM pass phrase:\"
  send \"test\n\"
  interact
"
sleep 1

# tcpdump to check communication
sudo tcpdump -i lo -tnlA "tcp and port 54321" -w - > tls.cap &
sleep 1

# launch udp client
echo "Hello, World!" | ncat 127.0.0.1 54321 --ssl-verify --ssl-trustfile test-cert.pem &
sleep 1

# delete task
kill %1 > /dev/null 2>&1
kill %3 > /dev/null 2>&1
jobs > /dev/null 2>&1
jobs -l | awk -F' ' '{print $2}' | xargs sudo kill > /dev/null 2>&1
sleep 1
jobs  > /dev/null 2>&1

#delete self certification
sudo rm -rf ./test-key.pem ./test-cert.pem
