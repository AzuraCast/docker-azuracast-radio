#
# Liquidsoap Build Stage
#
FROM ocaml/opam2:ubuntu-18.04-ocaml-4.07 AS liquidsoap

WORKDIR /home/opam

ARG opam_packages="taglib.0.3.3 mad.0.4.5 faad.0.4.0 fdkaac.0.2.1 lame.0.3.3 vorbis.0.7.1 cry.0.6.0 duppy.0.8.0 opus.0.1.2 flac.0.1.3 ssl liquidsoap.1.3.4"

USER root
RUN mkdir -p /var/azuracast/servers/liquidsoap \
    && chown opam:opam /var/azuracast/servers/liquidsoap

USER opam

RUN opam switch create /var/azuracast/servers/liquidsoap 4.07.1

WORKDIR /var/azuracast/servers/liquidsoap

# Load dependencies into a file that can be pulled by the main build.
RUN opam depext -sn ${opam_packages} > /tmp/depexts; true

# Actually build Liquidsoap in this image
RUN sudo apt-get update \
    && opam depext -i ${opam_packages}

#
# Icecast Build Stage
#
FROM ubuntu:bionic AS icecast

ARG ICECAST_KH_VERSION="2.4.0-kh10-ac4"

WORKDIR /root

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget libxml2 \
        libxslt1-dev libvorbis-dev libssl-dev libcurl4-openssl-dev gcc pkg-config ca-certificates \
    && wget https://github.com/AzuraCast/icecast-kh-ac/archive/master.tar.gz \
    && tar --strip-components=1 -xzf master.tar.gz \
    && ./configure \
    && make \
    && make install

#
# Final build stage
#
FROM ubuntu:bionic

# Set time zone
ENV TZ="UTC"
RUN echo $TZ > /etc/timezone

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d

# Create directories
RUN mkdir -p /var/azuracast/servers/shoutcast2 \
    && mkdir -p /var/azuracast/servers/liquidsoap \
    && mkdir -p /var/azuracast/servers/station-watcher \
    && mkdir -p /var/azuracast/stations

RUN adduser --home /var/azuracast --disabled-password --gecos "" azuracast \
    && chown -R azuracast:azuracast /var/azuracast

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends curl git vim \
        sudo ca-certificates

# Install supervisord
RUN mkdir -p /var/log/supervisor

RUN apt-get update \
    && apt-get install -q -y supervisor

ADD ./supervisord.conf /etc/supervisor/supervisord.conf

# SHOUTcast 2 DNAS can not be "distributed" in any way, due to SHOUTcast's strict commercial license.
# Users must download the files from the SHOUTcast web site themselves.
VOLUME "/var/azuracast/servers/shoutcast2"

# Import Icecast-KH from build container
COPY --from=icecast /usr/local/bin/icecast /usr/local/bin/icecast
COPY --from=icecast /usr/local/share/icecast /usr/local/share/icecast

# Icecast runtime deps.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget libxml2 \
        libxslt1-dev libvorbis-dev

# Import Liquidsoap from build container
COPY --from=liquidsoap --chown=azuracast:azuracast /var/azuracast/servers/liquidsoap /var/azuracast/servers/liquidsoap

# For libfdk-aac-dev
RUN sed -e 's#main#main contrib non-free#' -i /etc/apt/sources.list

COPY --from=liquidsoap /tmp/depexts /tmp/depexts
RUN apt-get update \
    && cat /tmp/depexts | xargs apt-get install -q -y --no-install-recommends \
    && ln -s /var/azuracast/servers/liquidsoap/_opam/bin/liquidsoap /usr/local/bin/liquidsoap

WORKDIR /root

EXPOSE 9001
EXPOSE 8000-8500

# Include radio services in PATH
ENV PATH="${PATH}:/var/azuracast/servers/shoutcast2:/var/azuracast/servers/station-watcher"

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]