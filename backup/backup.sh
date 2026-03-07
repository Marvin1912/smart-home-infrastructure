#!/usr/bin/env bash
#
# backup.sh - Encrypted PostgreSQL database backup
#
# Creates a full database dump (all schemas and data), compresses it,
# encrypts it using hybrid RSA+AES encryption, and packages it as a zip file.
#
# Usage: ./backup.sh [--output-dir DIR] [--public-key PATH] [--watch-dir DIR]
#
# Environment Variables:
#   DB_HOST      - Database host (default: localhost)
#   DB_PORT      - Database port (default: 5432)
#   DB_NAME      - Database name (default: costs)
#   DB_USER      - Database user (default: marvin)
#   PGPASSWORD   - Database password (default: password)
#   BACKUP_DIR   - Output directory for backups (default: ./backups)
#   PUBLIC_KEY   - Path to RSA public key (default: ./keys/backup_public.pem)
#   WATCH_DIR    - Directory to atomically move the final zip into (optional, for file-watcher integration)

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-costs}"
DB_USER="${DB_USER:-marvin}"
export PGPASSWORD="${PGPASSWORD:-password}"

BACKUP_DIR="${BACKUP_DIR:-${SCRIPT_DIR}/backups}"
PUBLIC_KEY="${PUBLIC_KEY:-${SCRIPT_DIR}/keys/backup_public.pem}"
WATCH_DIR="${WATCH_DIR:-}"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --public-key)
            PUBLIC_KEY="$2"
            shift 2
            ;;
        --watch-dir)
            WATCH_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--output-dir DIR] [--public-key PATH] [--watch-dir DIR]"
            echo ""
            echo "Options:"
            echo "  --output-dir  Output directory for backups (default: ./backups)"
            echo "  --public-key  RSA public key path (default: ./keys/backup_public.pem)"
            echo "  --watch-dir   Directory to atomically move the final zip into (for file-watcher integration)"
            echo ""
            echo "Environment Variables:"
            echo "  DB_HOST      Database host (default: localhost)"
            echo "  DB_PORT      Database port (default: 5432)"
            echo "  DB_NAME      Database name (default: costs)"
            echo "  DB_USER      Database user (default: marvin)"
            echo "  PGPASSWORD   Database password (default: password)"
            echo "  BACKUP_DIR   Output directory (default: ./backups)"
            echo "  PUBLIC_KEY   RSA public key path (default: ./keys/backup_public.pem)"
            echo "  WATCH_DIR    Watch directory for atomic move (optional)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# File naming
DUMP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"
COMPRESSED_FILE="${DUMP_FILE}.gz"
ENCRYPTED_FILE="${COMPRESSED_FILE}.enc"
AES_KEY_FILE="${BACKUP_DIR}/aes_key_${TIMESTAMP}.bin"
ENCRYPTED_KEY_FILE="${AES_KEY_FILE}.enc"
FINAL_ZIP="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.zip"

# ============================================================================
# Functions
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -f "${DUMP_FILE}" "${COMPRESSED_FILE}" "${ENCRYPTED_FILE}" \
          "${AES_KEY_FILE}" "${ENCRYPTED_KEY_FILE}" 2>/dev/null || true
}

# Always clean up on exit
trap cleanup EXIT

check_prerequisites() {
    local missing=()

    for cmd in pg_dump openssl gzip zip; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR: Missing required tools: ${missing[*]}"
        log "Install them with: sudo apt-get install postgresql-client openssl gzip zip"
        exit 1
    fi
}

validate_public_key() {
    if [[ ! -f "${PUBLIC_KEY}" ]]; then
        log "ERROR: RSA public key not found at: ${PUBLIC_KEY}"
        log "Generate keys first: ./generate-keys.sh"
        exit 1
    fi

    # Validate it's a proper PEM public key
    if ! openssl pkey -pubin -in "${PUBLIC_KEY}" -noout 2>/dev/null; then
        log "ERROR: Invalid RSA public key: ${PUBLIC_KEY}"
        exit 1
    fi

    log "Using public key: ${PUBLIC_KEY}"
}

# ============================================================================
# Main
# ============================================================================

echo "============================================"
echo "  Encrypted Database Backup"
echo "============================================"
echo ""

log "Starting backup process..."
log "Database: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Step 0: Check prerequisites
check_prerequisites
validate_public_key

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Step 1: Dump the entire database (all schemas and data)
log "Step 1/6: Dumping database..."
pg_dump \
    --host="${DB_HOST}" \
    --port="${DB_PORT}" \
    --username="${DB_USER}" \
    --dbname="${DB_NAME}" \
    --format=plain \
    --no-owner \
    --no-privileges \
    --verbose \
    --file="${DUMP_FILE}" \
    2>&1 | while IFS= read -r line; do log "  pg_dump: ${line}"; done

if [[ ! -f "${DUMP_FILE}" ]] || [[ ! -s "${DUMP_FILE}" ]]; then
    log "ERROR: Database dump failed or produced empty file"
    exit 1
fi

DUMP_SIZE=$(du -h "${DUMP_FILE}" | cut -f1)
log "  Dump size: ${DUMP_SIZE}"

# Step 2: Compress the dump
log "Step 2/6: Compressing dump with gzip..."
gzip -9 "${DUMP_FILE}"

COMPRESSED_SIZE=$(du -h "${COMPRESSED_FILE}" | cut -f1)
log "  Compressed size: ${COMPRESSED_SIZE}"

# Step 3: Generate a random AES-256 key
log "Step 3/6: Generating random AES-256 key..."
openssl rand 32 > "${AES_KEY_FILE}"

# Step 4: Encrypt the compressed dump with AES-256-CBC
log "Step 4/6: Encrypting data with AES-256-CBC..."
openssl enc -aes-256-cbc \
    -salt \
    -pbkdf2 \
    -iter 100000 \
    -in "${COMPRESSED_FILE}" \
    -out "${ENCRYPTED_FILE}" \
    -pass file:"${AES_KEY_FILE}"

ENCRYPTED_SIZE=$(du -h "${ENCRYPTED_FILE}" | cut -f1)
log "  Encrypted size: ${ENCRYPTED_SIZE}"

# Step 5: Encrypt the AES key with RSA public key
log "Step 5/6: Encrypting AES key with RSA public key..."
openssl pkeyutl \
    -encrypt \
    -pubin \
    -inkey "${PUBLIC_KEY}" \
    -in "${AES_KEY_FILE}" \
    -out "${ENCRYPTED_KEY_FILE}"

# Step 6: Package into a zip file
log "Step 6/6: Packaging into zip archive..."

# Rename files for cleaner archive contents
ARCHIVE_DATA_NAME="${DB_NAME}_${TIMESTAMP}.sql.gz.enc"
ARCHIVE_KEY_NAME="${DB_NAME}_${TIMESTAMP}.key.enc"

cp "${ENCRYPTED_FILE}" "${BACKUP_DIR}/${ARCHIVE_DATA_NAME}"
cp "${ENCRYPTED_KEY_FILE}" "${BACKUP_DIR}/${ARCHIVE_KEY_NAME}"

(cd "${BACKUP_DIR}" && zip -j "${FINAL_ZIP}" "${ARCHIVE_DATA_NAME}" "${ARCHIVE_KEY_NAME}")

# Clean up the copies used for zipping
rm -f "${BACKUP_DIR}/${ARCHIVE_DATA_NAME}" "${BACKUP_DIR}/${ARCHIVE_KEY_NAME}"

FINAL_SIZE=$(du -h "${FINAL_ZIP}" | cut -f1)

echo ""
echo "============================================"
echo "  Backup Complete"
echo "============================================"
echo ""
log "Output file: ${FINAL_ZIP}"
log "File size:   ${FINAL_SIZE}"
log "Database:    ${DB_NAME}"
log "Timestamp:   ${TIMESTAMP}"
echo ""
echo "To restore this backup, run:"
echo "  ./restore.sh ${FINAL_ZIP}"
echo ""

# Optional: Atomically move the backup to a watch directory for file-watcher integration
if [[ -n "${WATCH_DIR}" ]]; then
    log "Moving backup to watch directory: ${WATCH_DIR}"
    mkdir -p "${WATCH_DIR}"
    mv "${FINAL_ZIP}" "${WATCH_DIR}/$(basename "${FINAL_ZIP}")"
    log "Backup moved to: ${WATCH_DIR}/$(basename "${FINAL_ZIP}")"
fi
