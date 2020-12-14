FROM ubuntu:20.10
RUN apt-get update
RUN apt-get upgrade
RUN apt-get install -y apt-utils
RUN apt-get install -y apt-transport-https mosquitto wget gnupg2 git mosquitto-clients
# also python3 python3-pip
# RUN pip install paho-mqtt
RUN sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
RUN sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
RUN apt-get update
RUN apt-get install -y dart
COPY leaf2mqtt.sh /root
COPY leaf2mqtt.dart /root
COPY pubspec.yaml /root
RUN cd /root && dart pub get
CMD /root/leaf2mqtt.sh

