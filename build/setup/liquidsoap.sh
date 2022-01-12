#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

# Packages required by Liquidsoap
$minimal_apt_get_install libao-dev libasound2-dev libavcodec-dev libavdevice-dev libavfilter-dev libavformat-dev \
    libavutil-dev libfaad-dev libfdk-aac-dev libflac-dev libfreetype-dev libgd-dev libjack-dev \
    libjpeg-dev liblo-dev libmad0-dev libmagic-dev libmp3lame-dev libopus-dev libpng-dev libportaudio2 \
    libpulse-dev libsamplerate0-dev libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev libshine-dev libsoundtouch-dev libspeex-dev \
    libsrt-dev libswresample-dev libswscale-dev libtag1-dev libtheora-dev libtiff-dev libx11-dev libxpm-dev bubblewrap

# Optional audio plugins
$minimal_apt_get_install frei0r-plugins-dev ladspa-sdk multimedia-audio-plugins swh-plugins tap-plugins lsp-plugins-ladspa
