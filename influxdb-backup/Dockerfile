FROM debian:bookworm-slim

ARG INFLUX_CLI_VERSION=2.7.5

RUN apt-get update && apt-get install -y \
    curl \
    openssl \
    tar \
    zip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL \
       "https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX_CLI_VERSION}-linux-amd64.tar.gz" \
       | tar xz --strip-components=1 -C /usr/local/bin influx

RUN mkdir -p /app/backup/keys

COPY backup.sh /app/backup/backup.sh
COPY keys/backup_public.pem /app/backup/keys/backup_public.pem

RUN chmod +x /app/backup/backup.sh

CMD ["/app/backup/backup.sh"]
