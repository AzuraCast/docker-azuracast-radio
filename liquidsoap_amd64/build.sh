#!/bin/bash
set -e
set -x

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
    build-essential libssl-dev libcurl4-openssl-dev bubblewrap unzip m4 software-properties-common \
    ocaml opam \
    autoconf automake

apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/tmp*
