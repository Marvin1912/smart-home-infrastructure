# Database Backup & Encryption

Encrypted backup system for the PostgreSQL database used by the adapter application. Backups are compressed and encrypted using hybrid RSA+AES encryption, producing a single `.zip` file safe for upload to external storage.

## Quick Start

```bash
# 1. Generate example RSA keys (replace with your own later)
./generate-keys.sh

# 2. Create an encrypted backup
./backup.sh

# 3. Restore from an encrypted backup
./restore.sh ./backups/costs_backup_20260301_120000.zip
```

## How It Works

Since RSA cannot directly encrypt large files, the system uses **hybrid encryption**:

1. **`pg_dump`** exports the entire database (all schemas and data) as a plain SQL file
2. **`gzip`** compresses the SQL dump
3. A random **AES-256** symmetric key is generated
4. The compressed dump is encrypted with **AES-256-CBC** using the random key
5. The AES key is encrypted with the **RSA public key**
6. Both encrypted files are packaged into a single **`.zip`** archive

To restore, the process is reversed using the RSA private key.

## Scripts

### `generate-keys.sh`

Generates a 4096-bit RSA key pair for encryption/decryption.

```bash
# Generate keys in the default location (./keys/)
./generate-keys.sh

# Generate keys in a custom directory
./generate-keys.sh /path/to/key/directory
```

### `backup.sh`

Creates an encrypted database backup.

```bash
# Using defaults (localhost:5432, database: costs, user: marvin)
./backup.sh

# Custom output directory
./backup.sh --output-dir /mnt/backups

# Custom public key
./backup.sh --public-key /path/to/my_public.pem

# With file-watcher integration (atomic move to watched directory)
./backup.sh --watch-dir /app/backup/in

# Using environment variables
DB_HOST=db.example.com DB_PORT=5432 DB_NAME=costs DB_USER=admin PGPASSWORD=secret ./backup.sh
```

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `costs` | Database name |
| `DB_USER` | `marvin` | Database user |
| `PGPASSWORD` | `password` | Database password |
| `BACKUP_DIR` | `./backups` | Output directory for backup files |
| `PUBLIC_KEY` | `./keys/backup_public.pem` | Path to RSA public key |
| `WATCH_DIR` | *(empty)* | Directory to atomically move the final zip into (for file-watcher integration) |

### `restore.sh`

Decrypts and restores a backup to the database.

```bash
# Full restore to database
./restore.sh ./backups/costs_backup_20260301_120000.zip

# Decrypt only (produces .sql file without restoring)
./restore.sh ./backups/costs_backup_20260301_120000.zip --decrypt-only

# Custom private key
./restore.sh ./backups/costs_backup_20260301_120000.zip --private-key /path/to/my_private.pem

# Restore to a different database
DB_HOST=db.example.com DB_NAME=costs_staging ./restore.sh ./backups/costs_backup_20260301_120000.zip
```

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `costs` | Database name |
| `DB_USER` | `marvin` | Database user |
| `PGPASSWORD` | `password` | Database password |
| `PRIVATE_KEY` | `./keys/backup_private.pem` | Path to RSA private key |

## Database Schemas

The backup includes all schemas in the `costs` database:

| Schema | Description |
|--------|-------------|
| `finance` | Daily costs, monthly costs, base costs, salary, special costs |
| `exports` | Export run tracking |
| `mental_arithmetic` | Arithmetic sessions, problems, settings |
| `plants` | Plant data with audit tables |
| `vocabulary` | Flashcards, decks, vocabulary |
| `images` | Image storage |
| `linkwarden` | Linkwarden data |
| `public` | Flyway history tables |

## Replacing Example Keys

The example keys in `keys/` are for development/testing only. To use your own keys:

### Option 1: Generate new keys with the helper script

```bash
./generate-keys.sh
# Confirm overwrite when prompted
```

### Option 2: Use your own existing keys

```bash
# Place your keys in the keys/ directory
cp /path/to/your/public_key.pem ./keys/backup_public.pem
cp /path/to/your/private_key.pem ./keys/backup_private.pem

# Or specify paths directly
./backup.sh --public-key /path/to/your/public_key.pem
./restore.sh backup.zip --private-key /path/to/your/private_key.pem
```

### Key Requirements

- RSA key, minimum 2048-bit (4096-bit recommended)
- PEM format
- Public key must be in SPKI/X.509 format (`-----BEGIN PUBLIC KEY-----`)
- Private key in PKCS#8 format (`-----BEGIN PRIVATE KEY-----`)

## Prerequisites

The following tools must be installed:

- `pg_dump` / `psql` — PostgreSQL client tools
- `openssl` — For RSA and AES encryption
- `gzip` / `gunzip` — For compression
- `zip` / `unzip` — For packaging

Install on Debian/Ubuntu:

```bash
sudo apt-get install postgresql-client openssl gzip zip
```

## Security Notes

- **Never commit private keys** to version control. The `keys/.gitignore` prevents this.
- The AES key is randomly generated per backup and securely discarded after encryption.
- Temporary unencrypted files are cleaned up automatically (even on script failure via `trap`).
- For production, consider using `.pgpass` or `pg_service.conf` instead of `PGPASSWORD`.
- Store the private key separately from the encrypted backups for proper security.

## File Structure

```
backup/
├── keys/
│   ├── .gitignore              # Prevents key files from being committed
│   ├── backup_public.pem       # RSA public key (for encryption)
│   └── backup_private.pem      # RSA private key (for decryption) - KEEP SECURE
├── backups/                    # Created automatically, contains backup .zip files
├── backup.sh                   # Main backup script
├── restore.sh                  # Restore/decrypt script
├── generate-keys.sh            # RSA key pair generator
└── README.md                   # This file
```
