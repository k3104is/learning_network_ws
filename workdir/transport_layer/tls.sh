#!/bin/bash
# generate a private key for a curve
openssl ecparam -name prime256v1 -genkey -noout -out private-key.pem

# create a self-signed certificate
openssl req -new -x509 \
  -key private-key.pem \
  -out cert.pem \
  -subj "/C=JP/ST=Nagoya/O=myhome/CN=localhost"
sleep 1

# launch server
sudo openssl s_server -accept 54321 -cert cert.pem -key private-key.pem &
sleep 1

# tcpdump to check communication
sudo tcpdump -i lo -tnlA "tcp and port 54321" -w - > tls.cap &
sleep 1

# launch client
echo "Hello, World!" | sudo openssl s_client -connect 127.0.0.1:54321 -CAfile cert.pem
sleep 1

# delete task
kill %1 > /dev/null 2>&1
kill %2 > /dev/null 2>&1
sleep 1

#delete self certification
sudo rm -rf ./private-key.pem ./cert.pem
