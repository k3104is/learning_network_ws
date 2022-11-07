#!/bin/bash

# set serial
echo "01" > serial

# generate a private key for a curve
openssl ecparam -name prime256v1 > ecdsaparam

# create a self-signed certificate
openssl req -nodes -x509 \
  -newkey ec:ecdsaparam \
  -keyout ca.key \
  -subj "/C=JP/ST=Nagoya/O=myhome/CN=localhost" \
  -days 3650 \
  -out ca.crt

# create server certificate
openssl ecparam -name prime256v1 > ecdsaparam
openssl req -nodes \
  -newkey ec:ecdsaparam \
  -keyout server.key \
  -subj "/C=JP/ST=Nagoya/O=myhome/CN=server" \
  -out server.csr
openssl x509 -req \
  -in ./server.csr \
  -CA ca.crt \
  -CAserial serial \
  -CAkey ca.key \
  -out server.crt

# create client certificate
openssl ecparam -name prime256v1 > ecdsaparam
openssl req -nodes \
  -newkey ec:ecdsaparam \
  -keyout client.key \
  -subj "/C=JP/ST=Nagoya/O=myhome/CN=client" \
  -out client.csr
openssl x509 -req \
  -in client.csr \
  -CA ca.crt \
  -CAserial serial \
  -CAkey ca.key \
  -out client.crt

# launch server
sudo openssl s_server \
  -accept 54321 \
  -cert server.crt \
  -key server.key \
  -CAfile ca.crt &
sleep 1

# tcpdump to check communication
sudo tcpdump -i lo -tnlA "tcp and port 54321" -w - > tls.cap &
sleep 2

# launch client
echo "Hello, World!" | sudo openssl s_client \
  -connect 127.0.0.1:54321 \
  -cert client.crt \
  -key client.key \
  -CAfile ca.crt \
  > /dev/null 2>&1
sleep 2

# delete task
jobs -l | awk -F' ' '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
sleep 1

#delete self certification
sudo rm -rf ./*.csr ./*.pem ./*.crt ./*.key ecdsaparam serial
