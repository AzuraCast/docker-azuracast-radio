#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

# Install scripts commonly used during setup.
$minimal_apt_get_install curl wget tar zip unzip git rsync tzdata gpg-agent

# Run service setup for all setup scripts
for f in /bd_build/setup/*.sh; do
  bash "$f" -H 
done