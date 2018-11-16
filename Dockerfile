FROM ubuntu:bionic

# Set time zone
ENV TZ="UTC"
RUN echo $TZ > /etc/timezone

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d

# Create directories
RUN mkdir -p /var/azuracast/servers/shoutcast2 \
    && mkdir -p /var/azuracast/servers/icecast2 \
    && mkdir -p /var/azuracast/servers/station-watcher \
    && mkdir -p /var/azuracast/servers/stereotool \
    && mkdir -p /var/azuracast/stations

RUN adduser --home /var/azuracast --disabled-password --gecos "" azuracast \
    && chown -R azuracast:azuracast /var/azuracast

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends wget curl git vim \
        libssl-dev libcurl4-openssl-dev gcc pkg-config sudo ca-certificates

# Install supervisord
RUN mkdir -p /var/log/supervisor

RUN apt-get update \
    && apt-get install -q -y supervisor

ADD ./supervisord.conf /etc/supervisor/supervisord.conf

# SHOUTcast 2 DNAS can not be "distributed" in any way, due to SHOUTcast's strict commercial license.
# Users must download the files from the SHOUTcast web site themselves.
VOLUME "/var/azuracast/servers/shoutcast2"

# Download and build IceCast-KH
WORKDIR /var/azuracast/servers/icecast2

ENV ICECAST_KH_VERSION="2.4.0-kh10"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libxml2 \
        libxslt1-dev libvorbis-dev \
    && wget https://github.com/AzuraCast/icecast-kh-ac/archive/master.tar.gz \
    && tar --strip-components=1 -xzf master.tar.gz \
    && rm master.tar.gz \
    && ./configure \
    && make \
    && make install

# Build LiquidSoap

# For libfdk-aac-dev
RUN sed -e 's#main#main contrib non-free#' -i /etc/apt/sources.list

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive  apt-get install -y --no-install-recommends ocaml rsync opam \
      libpcre3-dev libfdk-aac-dev libmad0-dev libmp3lame-dev libtag1-dev libfaad-dev libflac-dev \
      libogg-dev libopus-dev m4 aspcud camlp4

USER azuracast

RUN opam init -a \
    && opam install -y taglib.0.3.3 mad.0.4.5 faad.0.4.0 fdkaac.0.2.1 lame.0.3.3 vorbis.0.7.0 cry.0.6.0 \
    duppy.0.8.0 opus.0.1.2 flac.0.1.2 liquidsoap.1.3.4

# Install the station-watcher app
USER root

WORKDIR /var/azuracast/servers/station-watcher
COPY ./station-watcher ./station-watcher

RUN chown azuracast:azuracast ./station-watcher \
    && chmod a+x ./station-watcher

WORKDIR /root

EXPOSE 9001
EXPOSE 8000-8500

# Include radio services in PATH
ENV PATH="${PATH}:/var/azuracast/.opam/system/bin:/var/azuracast/servers/shoutcast2:/var/azuracast/servers/station-watcher"

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]