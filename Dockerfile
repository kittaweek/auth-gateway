FROM dexidp/dex:v2.45.1
USER root
RUN apk upgrade --no-cache zlib
USER dex
