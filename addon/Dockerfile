ARG BUILD_VERSION
FROM yp87/leaf2mqtt:${BUILD_VERSION} AS build
FROM alpine

COPY --from=build / /
COPY root/ /

RUN \
    apk add --no-cache --virtual .build-dependencies \
      curl \
    \
    && apk add --no-cache \
        bash \
        jq \
        ca-certificates \
    \
    && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.7.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /tmp/* \
    \
    && apk del --no-cache --purge .build-dependencies \
    \
    && chmod +x /start.sh

CMD ["/start.sh"]
