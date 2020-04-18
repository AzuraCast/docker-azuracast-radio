#
# Base image
#
FROM ubuntu:bionic AS base

# Set time zone
ENV TZ="UTC"

# Add source for libopus from Ubuntu 19.04
COPY ./disco.list /etc/apt/sources.list.d/disco.list
COPY ./disco /etc/apt/preferences.d/disco

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
FROM azuracast/icecast-kh-ac:2.4.0-kh10-ac4 AS icecast

#
# Liquidsoap build stage
#
FROM base AS liquidsoap

# Install build tools
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
        build-essential libssl-dev libcurl4-openssl-dev bubblewrap unzip m4 software-properties-common \
    && add-apt-repository -y ppa:avsm/ppa \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends ocaml opam

USER azuracast

RUN opam init --disable-sandboxing -a --bare && opam switch create 4.08.0 

ARG opam_packages="samplerate.0.1.4 taglib.0.3.3 mad.0.4.5 faad.0.4.0 fdkaac.0.3.1 lame.0.3.3 vorbis.0.7.1 cry.0.6.1 flac.0.1.5 opus.0.1.3 duppy.0.8.0 ssl liquidsoap.1.4.1"
RUN opam install -y ${opam_packages}

#
# Main image
#
FROM base

# Import Icecast-KH from build container
COPY --from=icecast /usr/local/bin/icecast /usr/local/bin/icecast
COPY --from=icecast /usr/local/share/icecast /usr/local/share/icecast

# Import Liquidsoap from build container
COPY --from=liquidsoap --chown=azuracast:azuracast /var/azuracast/.opam/4.08.0 /var/azuracast/.opam/4.08.0

RUN ln -s /var/azuracast/.opam/4.08.0/bin/liquidsoap /usr/local/bin/liquidsoap

EXPOSE 9001
EXPOSE 8000-8999

# Include radio services in PATH
ENV PATH="${PATH}:/var/azuracast/servers/shoutcast2"
VOLUME ["/var/azuracast/servers/shoutcast2", "/var/azuracast/www_tmp"]

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]