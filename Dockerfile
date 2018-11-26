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
COPY --from=azuracast/azuracast_icecast:latest /usr/local/bin/icecast /usr/local/bin/icecast
COPY --from=azuracast/azuracast_icecast:latest /usr/local/share/icecast /usr/local/share/icecast

# Icecast runtime deps.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget libxml2 \
        libxslt1-dev libvorbis-dev

# Import Liquidsoap from build container
COPY --from=azuracast/azuracast_liquidsoap:latest --chown=azuracast:azuracast /var/azuracast/servers/liquidsoap /var/azuracast/servers/liquidsoap

# For libfdk-aac-dev
RUN sed -e 's#main#main contrib non-free#' -i /etc/apt/sources.list

COPY --from=azuracast/azuracast_liquidsoap:latest /tmp/depexts /tmp/depexts
RUN apt-get update \
    && cat /tmp/depexts | xargs apt-get install -q -y --no-install-recommends \
    && ln -s /var/azuracast/servers/liquidsoap/_opam/bin/liquidsoap /usr/local/bin/liquidsoap

# Install the station-watcher app
WORKDIR /var/azuracast/servers/station-watcher
COPY ./station-watcher ./station-watcher

RUN chown azuracast:azuracast ./station-watcher \
    && chmod a+x ./station-watcher

WORKDIR /root

EXPOSE 9001
EXPOSE 8000-8500

# Include radio services in PATH
ENV PATH="${PATH}:/var/azuracast/servers/shoutcast2:/var/azuracast/servers/station-watcher"

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]