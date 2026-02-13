# STAGE 1: Build the app in a legacy-compatible environment (Ubuntu 18.04)
# This ensures native modules like node-groove and leveldown compile correctly.
FROM ubuntu:18.04 AS builder

WORKDIR /home/groovebasin

# Install legacy build tools and libraries
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    make python g++ curl git ffmpeg pkg-config \
    libspeexdsp-dev libebur128-dev libsoundio-dev libchromaprint-dev \
    libgroove-dev libgrooveplayer-dev libgrooveloudness-dev \
    libgroovefingerprinter-dev

# Install Node.js 8.17.0
RUN curl -fsSL https://nodejs.org/dist/v8.17.0/node-v8.17.0-linux-x64.tar.gz | tar -xzC /usr/local --strip-components=1

# Install app dependencies
COPY package.json .
RUN npm install

# Copy source and build assets
COPY . .
RUN ./build

# ---
# STAGE 2: Final Runtime Image (Ubuntu 22.04)
# This provides Python 3.10 out of the box for modern yt-dlp compatibility.
FROM ubuntu:22.04

WORKDIR /home/groovebasin

# Avoid interaction during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
# We install the same lib versions (4) as in 18.04 to maintain binary compatibility.
RUN apt-get update && apt-get install -y \
    curl ffmpeg python3 \
    libspeexdsp1 libebur128-1 libsoundio2 libchromaprint1 \
    libgroove4 libgrooveplayer4 libgrooveloudness4 libgroovefingerprinter4 \
    && ln -sf /usr/bin/python3 /usr/bin/python


# Install Node.js 20.x (for yt-dlp EJS support)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    ln -sf /usr/bin/node /usr/local/bin/node

# Copy everything from the builder stage
COPY --from=builder /home/groovebasin /home/groovebasin

# Install yt-dlp (modern, robust YouTube downloader/searcher)
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# Create default config.json
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
    "ignoreExtensions": [\n\
        ".jpg", ".jpeg", ".txt", ".png", ".log", ".cue", ".pdf", ".m3u",\n\
        ".nfo", ".ini", ".xml", ".zip"\n\
    ]\n\
}' > config.json

# Expose ports
EXPOSE 16242
EXPOSE 6600

# Create music directory
RUN mkdir -p /home/groovebasin/music

CMD ["npm", "start"]