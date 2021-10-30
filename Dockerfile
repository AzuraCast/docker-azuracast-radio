#
# Base image
#
FROM ubuntu:focal AS base

# Set time zone
ENV TZ="UTC"

# Run base build process
COPY ./build/ /bd_build

RUN chmod a+x /bd_build/*.sh \
    && /bd_build/prepare.sh \
    && /bd_build/add_user.sh \
    && /bd_build/setup.sh \
    && /bd_build/cleanup.sh \
    && rm -rf /bd_build

#
# Icecast build stage (for later copy)
#
FROM azuracast/icecast-kh-ac:2.4.0-kh15-ac1 AS icecast

#
# Liquidsoap build stage
#
FROM base AS liquidsoap

# Install build tools
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
        build-essential libssl-dev libcurl4-openssl-dev bubblewrap unzip m4 software-properties-common \
        ocaml opam ffmpeg \
        autoconf automake

USER azuracast

RUN opam init --disable-sandboxing -a --bare && opam switch create 4.12.0

# Uncomment to Pin specific commit of Liquidsoap
RUN cd ~/ \
     && git clone --recursive https://github.com/savonet/liquidsoap.git \
    && cd liquidsoap \
    && git checkout bd9a2e3531ec03bae4f2812b6d83bdacf2277f0c \
    && opam pin add --no-action liquidsoap .

ARG opam_packages="ladspa.0.2.0 ffmpeg.1.0.1 ffmpeg-avutil.1.0.1 ffmpeg-avcodec.1.0.1 ffmpeg-avdevice.1.0.1 ffmpeg-av.1.0.1 ffmpeg-avfilter.1.0.1 ffmpeg-swresample.1.0.1 ffmpeg-swscale.1.0.1 frei0r.0.1.2 samplerate.0.1.6 taglib.0.3.6 mad.0.5.0 faad.0.5.0 fdkaac.0.3.2 lame.0.3.4 vorbis.0.8.0 cry.0.6.5 flac.0.3.0 opus.0.2.0 dtools.0.4.4 duppy.0.9.2 ocurl.0.9.1 ssl liquidsoap"
RUN opam install -y ${opam_packages}

#
# Main image
#
FROM base

# Import Icecast-KH from build container
COPY --from=icecast /usr/local/bin/icecast /usr/local/bin/icecast
COPY --from=icecast /usr/local/share/icecast /usr/local/share/icecast

# Import Liquidsoap from build container
COPY --from=liquidsoap --chown=azuracast:azuracast /var/azuracast/.opam/4.12.0 /var/azuracast/.opam/4.12.0

RUN ln -s /var/azuracast/.opam/4.12.0/bin/liquidsoap /usr/local/bin/liquidsoap

EXPOSE 9001
EXPOSE 8000-8999

# Include radio services in PATH
ENV PATH="${PATH}:/var/azuracast/servers/shoutcast2"
VOLUME ["/var/azuracast/servers/shoutcast2", "/var/azuracast/www_tmp"]

CMD ["/usr/local/bin/my_init"]
