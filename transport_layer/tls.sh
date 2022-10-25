#!/bin/bash
# generate a private key for a curve
openssl ecparam -name prime256v1 -genkey -noout -out ca.key

# create a self-signed certificate
openssl req -new -x509 \
  -key ca.key \
  -out ca.crt \
  -subj "/C=JP/ST=Nagoya/O=myhome/CN=localhost"
sleep 1

# create server certificate
openssl ecparam -name prime256v1 -genkey -noout -out server.key
openssl req -new \
  -key server.key \
  -out server.csr \
  -subj "/C=JP/ST=Nagoya/O=myhome/CN=server"
openssl x509 -req -in ./server.csr \
  -CA ca.crt \
  -CAkey ./ca.key \
  -out server.crt

# create server certificate
openssl ecparam -name prime256v1 -genkey -noout -out client.key
openssl req -new \
  -key client.key \
  -out client.csr \
  -subj "/C=JP/ST=Nagoya/O=myhome/CN=client"
openssl x509 -req -in ./client.csr \
  -CA ca.crt \
  -CAkey ./ca.key \
  -out client.crt

# launch server
sudo openssl s_server -accept 54321 -cert server.crt -key server.key -CAfile ca.crt &
sleep 1

# tcpdump to check communication
sudo tcpdump -i lo -tnlA "tcp and port 54321" -w - > tls.cap &
sleep 2

# launch client
echo "Hello, World!" | sudo openssl s_client -connect 127.0.0.1:54321 -cert client.crt -key client.key -CAfile ca.crt
sleep 2

# delete task
kill %1 > /dev/null 2>&1
kill %2 > /dev/null 2>&1
sleep 1

#delete self certification
sudo rm -rf ./*.csr ./*.pem
