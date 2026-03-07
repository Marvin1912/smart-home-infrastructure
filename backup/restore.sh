#!/usr/bin/env bash
#
# restore.sh - Decrypt and restore a PostgreSQL database backup
#
# Decrypts an encrypted backup zip created by backup.sh and restores it
# to the target PostgreSQL database.
#
# Usage: ./restore.sh <backup_zip_file> [--private-key PATH] [--decrypt-only]
#
# Environment Variables:
#   DB_HOST      - Database host (default: localhost)
#   DB_PORT      - Database port (default: 5432)
#   DB_NAME      - Database name (default: costs)
#   DB_USER      - Database user (default: marvin)
#   PGPASSWORD   - Database password (default: password)
#   PRIVATE_KEY  - Path to RSA private key (default: ./keys/backup_private.pem)

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-costs}"
DB_USER="${DB_USER:-marvin}"
export PGPASSWORD="${PGPASSWORD:-password}"

PRIVATE_KEY="${PRIVATE_KEY:-${SCRIPT_DIR}/keys/backup_private.pem}"
DECRYPT_ONLY=false

# ============================================================================
# Parse arguments
# ============================================================================

BACKUP_ZIP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --private-key)
            PRIVATE_KEY="$2"
            shift 2
            ;;
        --decrypt-only)
            DECRYPT_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 <backup_zip_file> [--private-key PATH] [--decrypt-only]"
            echo ""
            echo "Arguments:"
            echo "  backup_zip_file   Path to the encrypted backup zip file"
            echo ""
            echo "Options:"
            echo "  --private-key     Path to RSA private key (default: ./keys/backup_private.pem)"
            echo "  --decrypt-only    Only decrypt, do not restore to database"
            echo ""
            echo "Environment Variables:"
            echo "  DB_HOST      Database host (default: localhost)"
            echo "  DB_PORT      Database port (default: 5432)"
            echo "  DB_NAME      Database name (default: costs)"
            echo "  DB_USER      Database user (default: marvin)"
            echo "  PGPASSWORD   Database password (default: password)"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            BACKUP_ZIP="$1"
            shift
            ;;
    esac
done

if [[ -z "${BACKUP_ZIP}" ]]; then
    echo "ERROR: No backup zip file specified."
    echo "Usage: $0 <backup_zip_file> [--private-key PATH] [--decrypt-only]"
    exit 1
fi

# ============================================================================
# Functions
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

TEMP_DIR=""

cleanup() {
    log "Cleaning up temporary files..."
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}

trap cleanup EXIT

check_prerequisites() {
    local missing=()

    for cmd in openssl gunzip unzip; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [[ "${DECRYPT_ONLY}" == false ]]; then
        if ! command -v psql &>/dev/null; then
            missing+=("psql")
        fi
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR: Missing required tools: ${missing[*]}"
        log "Install them with: sudo apt-get install postgresql-client openssl gzip unzip"
        exit 1
    fi
}

validate_private_key() {
    if [[ ! -f "${PRIVATE_KEY}" ]]; then
        log "ERROR: RSA private key not found at: ${PRIVATE_KEY}"
        log "Specify the correct path with: --private-key /path/to/key.pem"
        exit 1
    fi

    if ! openssl pkey -in "${PRIVATE_KEY}" -noout 2>/dev/null; then
        log "ERROR: Invalid RSA private key: ${PRIVATE_KEY}"
        exit 1
    fi

    log "Using private key: ${PRIVATE_KEY}"
}

validate_backup_file() {
    if [[ ! -f "${BACKUP_ZIP}" ]]; then
        log "ERROR: Backup file not found: ${BACKUP_ZIP}"
        exit 1
    fi

    if ! file "${BACKUP_ZIP}" | grep -qi "zip"; then
        log "WARNING: File may not be a valid zip archive: ${BACKUP_ZIP}"
    fi

    log "Using backup file: ${BACKUP_ZIP}"
}

# ============================================================================
# Main
# ============================================================================

echo "============================================"
echo "  Encrypted Database Restore"
echo "============================================"
echo ""

log "Starting restore process..."

# Step 0: Check prerequisites
check_prerequisites
validate_private_key
validate_backup_file

# Create temporary working directory
TEMP_DIR="$(mktemp -d)"
log "Working directory: ${TEMP_DIR}"

# Step 1: Unzip the archive
log "Step 1/5: Extracting zip archive..."
unzip -o "${BACKUP_ZIP}" -d "${TEMP_DIR}"

# Find the encrypted data and key files
ENCRYPTED_DATA=$(find "${TEMP_DIR}" -name "*.sql.gz.enc" | head -1)
ENCRYPTED_KEY=$(find "${TEMP_DIR}" -name "*.key.enc" | head -1)

if [[ -z "${ENCRYPTED_DATA}" || -z "${ENCRYPTED_KEY}" ]]; then
    log "ERROR: Could not find encrypted data (.sql.gz.enc) or key (.key.enc) in archive"
    log "Archive contents:"
    ls -la "${TEMP_DIR}"
    exit 1
fi

log "  Found encrypted data: $(basename "${ENCRYPTED_DATA}")"
log "  Found encrypted key:  $(basename "${ENCRYPTED_KEY}")"

# Step 2: Decrypt the AES key using RSA private key
log "Step 2/5: Decrypting AES key with RSA private key..."
AES_KEY_FILE="${TEMP_DIR}/aes_key.bin"
openssl pkeyutl \
    -decrypt \
    -inkey "${PRIVATE_KEY}" \
    -in "${ENCRYPTED_KEY}" \
    -out "${AES_KEY_FILE}"

# Step 3: Decrypt the data using AES key
log "Step 3/5: Decrypting data with AES-256-CBC..."
COMPRESSED_FILE="${TEMP_DIR}/backup.sql.gz"
openssl enc -d -aes-256-cbc \
    -salt \
    -pbkdf2 \
    -iter 100000 \
    -in "${ENCRYPTED_DATA}" \
    -out "${COMPRESSED_FILE}" \
    -pass file:"${AES_KEY_FILE}"

# Step 4: Decompress
log "Step 4/5: Decompressing..."
gunzip "${COMPRESSED_FILE}"
SQL_FILE="${TEMP_DIR}/backup.sql"

SQL_SIZE=$(du -h "${SQL_FILE}" | cut -f1)
log "  Decompressed SQL dump size: ${SQL_SIZE}"

if [[ "${DECRYPT_ONLY}" == true ]]; then
    # Copy the decrypted SQL to the current directory
    OUTPUT_SQL="$(dirname "${BACKUP_ZIP}")/$(basename "${BACKUP_ZIP}" .zip).sql"
    cp "${SQL_FILE}" "${OUTPUT_SQL}"
    echo ""
    echo "============================================"
    echo "  Decryption Complete (--decrypt-only)"
    echo "============================================"
    echo ""
    log "Decrypted SQL dump: ${OUTPUT_SQL}"
    log "File size: ${SQL_SIZE}"
    echo ""
    echo "To manually restore, run:"
    echo "  psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -f ${OUTPUT_SQL}"
    echo ""
    exit 0
fi

# Step 5: Restore to database
log "Step 5/5: Restoring to database ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}..."
echo ""

read -rp "This will restore the backup to database '${DB_NAME}'. Continue? (y/N): " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    echo "Aborted. Database was not modified."
    exit 0
fi

psql \
    --host="${DB_HOST}" \
    --port="${DB_PORT}" \
    --username="${DB_USER}" \
    --dbname="${DB_NAME}" \
    --file="${SQL_FILE}" \
    --set ON_ERROR_STOP=off \
    2>&1 | while IFS= read -r line; do log "  psql: ${line}"; done

echo ""
echo "============================================"
echo "  Restore Complete"
echo "============================================"
echo ""
log "Database '${DB_NAME}' has been restored from: $(basename "${BACKUP_ZIP}")"
echo ""
