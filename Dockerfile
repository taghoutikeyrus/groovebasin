FROM ubuntu:16.04

WORKDIR /home/groovebasin

RUN mkdir /home/groovebasin/music

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y make python g++ curl git \
    && curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh \
    && bash nodesource_setup.sh \
    && apt-get install -y --allow-unauthenticated nodejs \
    && npm install -g node-gyp

RUN apt-get -y install \
    ffmpeg libspeexdsp-dev \
    libebur128-dev libsoundio-dev libchromaprint-dev \
    libgroove-dev libgrooveplayer-dev libgrooveloudness-dev \
    libgroovefingerprinter-dev

COPY package.json .
RUN npm install

COPY . .
RUN ./build

# The ytdl-core patch was removed as it caused dependency issues on Node 8.
# If YouTube imports fail, consider updating ytdl-core in package.json.

# Create default config.json with all required settings to prevent exit on first run
RUN echo '{\n\
    "host": "0.0.0.0",\n\
    "port": 16242,\n\
    "dbPath": "groovebasin.db",\n\
    "musicDirectory": "/home/groovebasin/music",\n\
    "lastFmApiKey": "bb9b81026cd44fd086fa5533420ac9b4",\n\
    "lastFmApiSecret": "2309a40ae3e271de966bf320498a8f09",\n\
    "mpdHost": "0.0.0.0",\n\
    "mpdPort": 6600,\n\
    "acoustidAppKey": "bgFvC4vW",\n\
    "encodeQueueDuration": 8,\n\
    "encodeBitRate": 256,\n\
    "sslKey": null,\n\
    "sslCert": null,\n\
    "sslCaDir": null,\n\
    "googleApiKey": "AIzaSyDdTDD8-gu_kp7dXtT-53xKcVbrboNAkpM",\n\
    "ignoreExtensions": [\n\
        ".jpg", ".jpeg", ".txt", ".png", ".log", ".cue", ".pdf", ".m3u",\n\
        ".nfo", ".ini", ".xml", ".zip"\n\
    ]\n\
}' > config.json

EXPOSE 16242
EXPOSE 6600

CMD ["npm", "start"]