FROM ubuntu:20.10
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y apt-transport-https mosquitto wget gnupg2 git mosquitto-clients && rm -rf /var/lib/apt/lists/*
RUN sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
RUN sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
COPY leaf2mqtt.sh /root
COPY leaf2mqtt-once.sh /root
COPY leaf2mqtt.dart /root
COPY listener.sh /root
COPY leaf_climate.dart /root
COPY pubspec.yaml /root
RUN apt-get update && apt-get install -y --no-install-recommends dart && cd /root && dart pub get && dart compile exe leaf2mqtt.dart && dart compile exe leaf_climate.dart && apt-get purge -y apt-transport-https wget gnupg2 git dart && rm -rf /var/lib/apt/lists/*
RUN apt-get autoremove --purge -y
CMD /root/leaf2mqtt.sh

