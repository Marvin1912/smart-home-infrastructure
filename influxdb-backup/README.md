# InfluxDB Backup & Encryption

Encrypted backup system for the InfluxDB instance. Backups are compressed and encrypted using hybrid RSA+AES encryption, producing a single `.zip` file safe for upload to external storage.

The approach mirrors the Postgres backup in `../backup/` and uses the same encryption scheme — the RSA key pair can be shared between both.

## Quick Start

```bash
# 1. Generate RSA keys (or reuse keys from ../backup/keys/)
../backup/generate-keys.sh ./keys

# 2. Create an encrypted backup
INFLUX_TOKEN=<your-token> ./backup.sh

# 3. Restore from an encrypted backup
INFLUX_TOKEN=<your-token> ./restore.sh ./backups/influxdb_backup_20260301_120000.zip
```

## How It Works

Since RSA cannot directly encrypt large files, the system uses **hybrid encryption**:

1. **`influx backup`** exports the full InfluxDB instance (all buckets, metadata, tasks) as a snapshot directory
2. **`tar + gzip`** compresses the snapshot directory into a `.tar.gz` archive
3. A random **AES-256** symmetric key is generated
4. The compressed archive is encrypted with **AES-256-CBC** using the random key
5. The AES key is encrypted with the **RSA public key**
6. Both encrypted files are packaged into a single **`.zip`** archive

To restore, the process is reversed using the RSA private key.

## Scripts

### `backup.sh`

Creates an encrypted InfluxDB backup.

```bash
# Using defaults (http://localhost:8086, org: wildfly_domain, all buckets)
INFLUX_TOKEN=<token> ./backup.sh

# Custom output directory
INFLUX_TOKEN=<token> ./backup.sh --output-dir /mnt/backups

# Back up a specific bucket only
INFLUX_TOKEN=<token> INFLUX_BUCKET=sensor_data ./backup.sh

# With file-watcher integration (atomic move to watched directory)
INFLUX_TOKEN=<token> ./backup.sh --watch-dir /app/backup/in
```

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `INFLUX_URL` | `http://localhost:8086` | InfluxDB URL |
| `INFLUX_TOKEN` | *(required)* | API token with read access |
| `INFLUX_ORG` | `wildfly_domain` | Organization name |
| `INFLUX_BUCKET` | *(empty = all buckets)* | Specific bucket to back up |
| `BACKUP_DIR` | `./backups` | Output directory for backup files |
| `PUBLIC_KEY` | `./keys/backup_public.pem` | Path to RSA public key |
| `WATCH_DIR` | *(empty)* | Directory to atomically move the final zip into |

### `restore.sh`

Decrypts and restores a backup to InfluxDB.

```bash
# Restore data to InfluxDB
INFLUX_TOKEN=<token> ./restore.sh ./backups/influxdb_backup_20260301_120000.zip

# Full restore: also restores metadata (tokens, users, dashboards)
INFLUX_TOKEN=<token> ./restore.sh ./backups/influxdb_backup_20260301_120000.zip --full

# Decrypt only (produces snapshot directory without restoring)
./restore.sh ./backups/influxdb_backup_20260301_120000.zip --decrypt-only

# Custom private key
INFLUX_TOKEN=<token> ./restore.sh ./backups/influxdb_backup_20260301_120000.zip --private-key /path/to/my_private.pem
```

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `INFLUX_URL` | `http://localhost:8086` | InfluxDB URL |
| `INFLUX_TOKEN` | *(required)* | API token with write access |
| `INFLUX_ORG` | `wildfly_domain` | Organization name |
| `PRIVATE_KEY` | `./keys/backup_private.pem` | Path to RSA private key |

**Flags:**

| Flag | Description |
|------|-------------|
| `--full` | Full restore: restores all metadata including tokens, users, and dashboards. Use with care on a running instance. |
| `--decrypt-only` | Decrypts the backup to a snapshot directory without restoring. Useful for inspection or manual restore. |

## InfluxDB Buckets

The backup covers all buckets in the `wildfly_domain` organization:

| Bucket | Retention | Description |
|--------|-----------|-------------|
| `costs` | infinite | Cost tracking data |
| `sensor_data` | ~212 days | Raw sensor readings |
| `sensor_data_30m` | infinite | Downsampled 30-minute aggregates |
| `system_metrics` | infinite | System metrics |

## Keys

RSA key pair requirements are identical to the Postgres backup. You can reuse the same key pair:

```bash
# Option 1: Reuse existing keys from the Postgres backup
cp ../backup/keys/backup_public.pem ./keys/backup_public.pem

# Option 2: Generate a dedicated key pair
../backup/generate-keys.sh ./keys
```

**Key Requirements:**
- RSA, minimum 2048-bit (4096-bit recommended)
- PEM format
- Public key in SPKI/X.509 format (`-----BEGIN PUBLIC KEY-----`)
- Private key in PKCS#8 format (`-----BEGIN PRIVATE KEY-----`)

## Docker

Build and push the Docker image to a local registry:

```bash
./build-and-push.sh

# Custom registry or tag
./build-and-push.sh --registry my-registry:5000 --tag v1.0.0
```

The image is based on `debian:bookworm-slim` and includes the `influx` CLI (v2.7.5), `openssl`, `tar`, and `zip`.

Run the container:

```bash
docker run --rm \
  -e INFLUX_URL=http://influxdb:8086 \
  -e INFLUX_TOKEN=<your-token> \
  -e INFLUX_ORG=wildfly_domain \
  -v /path/to/backups:/app/backup/backups \
  localhost:5000/influxdb-backup:latest
```

## Security Notes

- **Never commit private keys** to version control. The `keys/.gitignore` prevents this.
- The AES key is randomly generated per backup and securely discarded after encryption.
- Temporary unencrypted files are cleaned up automatically (even on failure via `trap`).
- Store the private key separately from the encrypted backups for proper security.
- `INFLUX_TOKEN` should be an API token with read-only access for backup, and write access for restore.

## File Structure

```
influxdb-backup/
├── keys/
│   ├── .gitignore              # Prevents key files from being committed
│   └── backup_public.pem       # RSA public key (for encryption) — add manually
├── backups/                    # Created automatically, contains backup .zip files
├── backup.sh                   # Main backup script
├── restore.sh                  # Restore/decrypt script
├── build-and-push.sh           # Build and push Docker image
├── Dockerfile                  # Docker image definition
└── README.md                   # This file
```
