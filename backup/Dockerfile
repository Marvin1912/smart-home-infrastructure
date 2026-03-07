FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    postgresql-client \
    openssl \
    gzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/backup/keys

COPY backup.sh /app/backup/backup.sh
COPY keys/backup_public.pem /app/backup/keys/backup_public.pem

RUN chmod +x /app/backup/backup.sh

CMD ["/app/backup/backup.sh"]
