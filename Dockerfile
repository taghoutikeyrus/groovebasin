FROM ubuntu:16.04

WORKDIR /home/groovebasin

RUN mkdir /home/groovebasin/music

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y make python g++ curl git \
    && curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh \
    && bash nodesource_setup.sh \
    && apt-get install -y nodejs \
    && npm install -g node-gyp

RUN apt-get -y install \
    ffmpeg libspeexdsp-dev \
    libebur128-dev libsoundio-dev libchromaprint-dev \
    libgroove-dev libgrooveplayer-dev libgrooveloudness-dev \
    libgroovefingerprinter-dev

COPY package.json .
RUN npm install

COPY . .
RUN npm run build

# Fix Youtube import error by updating ytdl-core module
RUN npm install ytdl-core@~0.29.5 --save

# Generate default config.json
RUN npm start; exit 0
# Modify default config.json
RUN sed -i 's/    "host": "127.0.0.1",/    "host": "0.0.0.0",/g' /home/groovebasin/config.json
RUN sed -i 's/    "mpdHost": "127.0.0.1",/    "mpdHost": "0.0.0.0",/g' /home/groovebasin/config.json
RUN sed -i 's/    "musicDirectory": "\/root",/    "musicDirectory": "\/home\/groovebasin\/music",/g' /home/groovebasin/config.json

EXPOSE 16242
EXPOSE 6600

CMD ["npm", "start"]