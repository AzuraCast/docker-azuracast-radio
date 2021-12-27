#!/bin/bash
set -e
set -x

opam init --disable-sandboxing -a --bare && opam switch create 4.12.0

# Pin specific commit of Liquidsoap
git clone --recursive https://github.com/savonet/liquidsoap.git /tmp/liquidsoap
cd /tmp/liquidsoap
git checkout 7bb1b39503ff4738f7ec98f82643ef31e6d4c94c
opam pin add --no-action liquidsoap .

git clone --recursive https://github.com/savonet/ocaml-ffmpeg.git /tmp/ocaml-ffmpeg
cd /tmp/ocaml-ffmpeg
git checkout 5b0ab162f977c25d51915a5b5019e03c33e6b63d
opam pin add --no-action ffmpeg .
opam pin add --no-action ffmpeg-avutil .
opam pin add --no-action ffmpeg-avcodec .
opam pin add --no-action ffmpeg-avdevice .
opam pin add --no-action ffmpeg-av .
opam pin add --no-action ffmpeg-avfilter .
opam pin add --no-action ffmpeg-swresample .
opam pin add --no-action ffmpeg-swscale .

opam install -y ladspa.0.2.0 ffmpeg.1.1.1 ffmpeg-avutil.1.1.1 ffmpeg-avcodec.1.1.1 ffmpeg-avdevice.1.1.1 \
    ffmpeg-av.1.1.1 ffmpeg-avfilter.1.1.1 ffmpeg-swresample.1.1.1 ffmpeg-swscale.1.1.1 frei0r.0.1.2 \
    samplerate.0.1.6 taglib.0.3.7 mad.0.5.0 faad.0.5.0 fdkaac.0.3.2 lame.0.3.5 vorbis.0.8.0 cry.0.6.5 \
    flac.0.3.0 opus.0.2.0 dtools.0.4.4 duppy.0.9.2 ocurl.0.9.1 ssl \
    liquidsoap
