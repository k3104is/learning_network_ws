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

# verify certificates
openssl verify -CAfile ca.crt ca.crt
openssl verify -CAfile ca.crt server.crt
openssl verify -CAfile ca.crt client.crt

