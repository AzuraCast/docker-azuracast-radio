#
# Base image
#
FROM phusion/baseimage:0.11 AS base

# Set time zone
ENV TZ="UTC"
RUN echo $TZ > /etc/timezone \
    # Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
    && sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d 
    
# Common packages
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
    # Base packages
    curl git ca-certificates tzdata supervisor tmpreaper \
    # Icecast 
    libxml2 libxslt1-dev libvorbis-dev \
    # Liquidsoap
    libfaad-dev libfdk-aac-dev libflac-dev libmad0-dev libmp3lame-dev libogg-dev \
    libopus-dev libpcre3-dev libtag1-dev libsamplerate0-dev \
    && rm -rf /var/lib/apt/lists/*

# Create directories and AzuraCast user
RUN mkdir -p /var/azuracast/servers/shoutcast2 /var/azuracast/stations /var/azuracast/www_tmp \
    && adduser --home /var/azuracast --disabled-password --gecos "" azuracast \
    && chown -R azuracast:azuracast /var/azuracast

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

ARG opam_packages="samplerate.0.1.4 taglib.0.3.3 mad.0.4.5 faad.0.4.0 fdkaac.0.2.1 lame.0.3.3 vorbis.0.7.1 cry.0.6.1 flac.0.1.4 opus.0.1.2 duppy.0.8.0 ssl liquidsoap.1.3.7"

RUN opam init --disable-sandboxing -a \
    && opam install -y ${opam_packages}

#
# Main image
#
FROM base

# Install Supervisor
COPY ./supervisord.conf /etc/supervisor/supervisord.conf

# Import Icecast-KH from build container
COPY --from=icecast /usr/local/bin/icecast /usr/local/bin/icecast
COPY --from=icecast /usr/local/share/icecast /usr/local/share/icecast

# Import Liquidsoap from build container
COPY --from=liquidsoap --chown=azuracast:azuracast /var/azuracast/.opam/default /var/azuracast/.opam/default

RUN ln -s /var/azuracast/.opam/default/bin/liquidsoap /usr/local/bin/liquidsoap

EXPOSE 9001
EXPOSE 8000-8999

# Include radio services in PATH
ENV PATH="${PATH}:/var/azuracast/servers/shoutcast2"
VOLUME ["/var/azuracast/servers/shoutcast2", "/var/azuracast/www_tmp"]

# Set up first-run scripts and runit services
COPY ./runit/ /etc/service/
COPY ./cron/ /etc/cron.d/

RUN chmod +x /etc/service/*/run \
    && chmod -R 600 /etc/cron.d/*

CMD ["/sbin/my_init"]