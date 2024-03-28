FROM ubuntu:22.04


RUN apt-get update -y
RUN apt-get install -y \
  iproute2 openssl tcpdump\
  vim git