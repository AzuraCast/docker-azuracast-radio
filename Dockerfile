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
FROM ghcr.io/azuracast/icecast-kh-ac:latest AS icecast

#
# Liquidsoap build stage
#
FROM base AS liquidsoap

# Run base build process
COPY ./liquidsoap_build/ /ls_build

RUN chmod a+x /ls_build/*.sh \
    && bash /ls_build/build.sh \
    && sudo -u azuracast bash /ls_build/build_as_azuracast.sh \
    && rm -rf /ls_build

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
