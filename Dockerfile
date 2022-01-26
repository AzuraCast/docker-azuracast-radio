
#
# Icecast build stage (for later copy)
#
FROM ghcr.io/azuracast/icecast-kh-ac@sha256:751ae244cc8a06487edff350eed330e1bc08fee6e9a4c7edd9881360f44c303f AS icecast

#
# Common base image
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
# AMD64 Liquidsoap Build Stage
#
FROM base AS liquidsoap_amd64

COPY ./liquidsoap_amd64/ /ls_build

RUN chmod a+x /ls_build/*.sh \
    && bash /ls_build/build.sh \
    && sudo -u azuracast bash /ls_build/build_as_azuracast.sh \
    && rm -rf /ls_build

#
# AMD64 Build Stage
#
FROM base AS build_amd64

COPY --from=liquidsoap_amd64 --chown=azuracast:azuracast /var/azuracast/.opam/4.12.0 /var/azuracast/.opam/4.12.0
RUN ln -s /var/azuracast/.opam/4.12.0/bin/liquidsoap /usr/local/bin/liquidsoap

#
# ARM64 Build Stage
#
FROM base AS build_arm64

RUN apt-get update \
    && wget -O /tmp/liquidsoap.deb "https://github.com/savonet/liquidsoap/releases/download/v2.0.2/liquidsoap_2.0.2-ubuntu-focal-1_arm64.deb" \
    && dpkg -i /tmp/liquidsoap.deb \
    && apt-get install -y -f --no-install-recommends \
    && rm -f /tmp/liquidsoap.deb \ 
    && ln -s /usr/bin/liquidsoap /usr/local/bin/liquidsoap

#
# Final image
#
FROM build_${TARGETARCH} AS final

# Import Icecast-KH from build container
COPY --from=icecast /usr/local/bin/icecast /usr/local/bin/icecast
COPY --from=icecast /usr/local/share/icecast /usr/local/share/icecast

EXPOSE 9001
EXPOSE 8000-8999

# Include radio services in PATH
ENV PATH="${PATH}:/var/azuracast/servers/shoutcast2"
VOLUME ["/var/azuracast/servers/shoutcast2", "/var/azuracast/www_tmp"]

CMD ["/usr/local/bin/my_init"]
