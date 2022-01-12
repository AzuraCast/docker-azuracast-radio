#!/bin/bash
set -e
set -x

opam init --disable-sandboxing -a --bare && opam switch create 4.12.0

# Pin specific commit of Liquidsoap
git clone --recursive https://github.com/savonet/liquidsoap.git /tmp/liquidsoap
cd /tmp/liquidsoap
git checkout 7d209e52e62bd0f0a59195fb4921e400de5ae97b
opam pin add --no-action liquidsoap .

opam install -y ladspa.0.2.0 ffmpeg.1.1.1 ffmpeg-avutil.1.1.1 ffmpeg-avcodec.1.1.1 ffmpeg-avdevice.1.1.1 \
    ffmpeg-av.1.1.1 ffmpeg-avfilter.1.1.1 ffmpeg-swresample.1.1.1 ffmpeg-swscale.1.1.1 frei0r.0.1.2 \
    samplerate.0.1.6 taglib.0.3.7 mad.0.5.0 faad.0.5.0 fdkaac.0.3.2 lame.0.3.5 vorbis.0.8.0 cry.0.6.5 \
    flac.0.3.0 opus.0.2.0 dtools.0.4.4 duppy.0.9.2 ocurl.0.9.1 ssl \
    liquidsoap
