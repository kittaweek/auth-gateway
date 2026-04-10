FROM dexidp/dex:v2.45.1
USER root
RUN apk update && apk add --no-cache zlib>=1.3.2-r0
USER dex
