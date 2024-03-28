FROM ubuntu:22.04


RUN apt-get update -y
RUN apt-get install -y \
  vim git