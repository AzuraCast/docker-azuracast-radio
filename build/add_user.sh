#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

$minimal_apt_get_install sudo

mkdir -p /var/azuracast/servers/shoutcast2 /var/azuracast/stations /var/azuracast/www_tmp 

adduser --home /var/azuracast --disabled-password --gecos "" azuracast

chown -R azuracast:azuracast /var/azuracast

echo 'azuracast ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers