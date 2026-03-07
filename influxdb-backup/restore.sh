#!/usr/bin/env bash
#
# restore.sh - Decrypt and restore an InfluxDB backup
#
# Decrypts an encrypted backup zip created by backup.sh and restores it
# to the target InfluxDB instance.
#
# Usage: ./restore.sh <backup_zip_file> [--private-key PATH] [--decrypt-only] [--full]
#
# Environment Variables:
#   INFLUX_URL    - InfluxDB URL (default: http://localhost:8086)
#   INFLUX_TOKEN  - InfluxDB API token with write access (REQUIRED unless --decrypt-only)
#   INFLUX_ORG    - InfluxDB organization name (default: wildfly_domain)
#   PRIVATE_KEY   - Path to RSA private key (default: ./keys/backup_private.pem)

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INFLUX_URL="${INFLUX_URL:-http://localhost:8086}"
INFLUX_ORG="${INFLUX_ORG:-wildfly_domain}"

PRIVATE_KEY="${PRIVATE_KEY:-${SCRIPT_DIR}/keys/backup_private.pem}"
DECRYPT_ONLY=false
FULL_RESTORE=false

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
        --full)
            FULL_RESTORE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 <backup_zip_file> [--private-key PATH] [--decrypt-only] [--full]"
            echo ""
            echo "Arguments:"
            echo "  backup_zip_file   Path to the encrypted backup zip file"
            echo ""
            echo "Options:"
            echo "  --private-key     Path to RSA private key (default: ./keys/backup_private.pem)"
            echo "  --decrypt-only    Only decrypt, do not restore to InfluxDB"
            echo "  --full            Full restore: restores all metadata and data (default: data only)"
            echo ""
            echo "Environment Variables:"
            echo "  INFLUX_URL    InfluxDB URL (default: http://localhost:8086)"
            echo "  INFLUX_TOKEN  InfluxDB API token with write access (REQUIRED)"
            echo "  INFLUX_ORG    InfluxDB organization name (default: wildfly_domain)"
            echo "  PRIVATE_KEY   Path to RSA private key (default: ./keys/backup_private.pem)"
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
    echo "Usage: $0 <backup_zip_file> [--private-key PATH] [--decrypt-only] [--full]"
    exit 1
fi

if [[ "${DECRYPT_ONLY}" == false && -z "${INFLUX_TOKEN:-}" ]]; then
    echo "ERROR: INFLUX_TOKEN environment variable is required for restore."
    echo "Use --decrypt-only to decrypt without restoring."
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

    for cmd in openssl tar unzip; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [[ "${DECRYPT_ONLY}" == false ]]; then
        if ! command -v influx &>/dev/null; then
            missing+=("influx")
        fi
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR: Missing required tools: ${missing[*]}"
        log "Install influx CLI from https://docs.influxdata.com/influxdb/v2/tools/influx-cli/"
        log "Install others with: sudo apt-get install openssl tar unzip"
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
echo "  Encrypted InfluxDB Restore"
echo "============================================"
echo ""

log "Starting restore process..."

# Step 0: Check prerequisites
check_prerequisites
validate_private_key
validate_backup_file

TEMP_DIR="$(mktemp -d)"
log "Working directory: ${TEMP_DIR}"

# Step 1: Unzip the archive
log "Step 1/5: Extracting zip archive..."
unzip -o "${BACKUP_ZIP}" -d "${TEMP_DIR}"

ENCRYPTED_DATA=$(find "${TEMP_DIR}" -name "*.tar.gz.enc" | head -1)
ENCRYPTED_KEY=$(find "${TEMP_DIR}" -name "*.key.enc" | head -1)

if [[ -z "${ENCRYPTED_DATA}" || -z "${ENCRYPTED_KEY}" ]]; then
    log "ERROR: Could not find encrypted data (.tar.gz.enc) or key (.key.enc) in archive"
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
ARCHIVE_FILE="${TEMP_DIR}/snapshot.tar.gz"
openssl enc -d -aes-256-cbc \
    -salt \
    -pbkdf2 \
    -iter 100000 \
    -in "${ENCRYPTED_DATA}" \
    -out "${ARCHIVE_FILE}" \
    -pass file:"${AES_KEY_FILE}"

# Step 4: Decompress tar archive
log "Step 4/5: Decompressing snapshot..."
SNAPSHOT_DIR="${TEMP_DIR}/snapshot"
mkdir -p "${SNAPSHOT_DIR}"
tar xzf "${ARCHIVE_FILE}" -C "${SNAPSHOT_DIR}" --strip-components=1

SNAPSHOT_SIZE=$(du -sh "${SNAPSHOT_DIR}" | cut -f1)
log "  Snapshot size: ${SNAPSHOT_SIZE}"

if [[ "${DECRYPT_ONLY}" == true ]]; then
    OUTPUT_DIR="$(dirname "${BACKUP_ZIP}")/$(basename "${BACKUP_ZIP}" .zip)_snapshot"
    cp -r "${SNAPSHOT_DIR}" "${OUTPUT_DIR}"
    echo ""
    echo "============================================"
    echo "  Decryption Complete (--decrypt-only)"
    echo "============================================"
    echo ""
    log "Decrypted snapshot: ${OUTPUT_DIR}"
    log "Snapshot size: ${SNAPSHOT_SIZE}"
    echo ""
    echo "To manually restore, run:"
    echo "  influx restore --host ${INFLUX_URL} --token \$INFLUX_TOKEN --org ${INFLUX_ORG} ${OUTPUT_DIR}"
    echo ""
    exit 0
fi

# Step 5: Restore to InfluxDB
log "Step 5/5: Restoring to InfluxDB at ${INFLUX_URL} (org: ${INFLUX_ORG})..."
echo ""

if [[ "${FULL_RESTORE}" == true ]]; then
    echo "WARNING: --full restore will overwrite all metadata including tokens, users, and dashboards."
fi

read -rp "This will restore the backup to InfluxDB at '${INFLUX_URL}'. Continue? (y/N): " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    echo "Aborted. InfluxDB was not modified."
    exit 0
fi

INFLUX_RESTORE_ARGS=(
    restore
    --host "${INFLUX_URL}"
    --token "${INFLUX_TOKEN}"
    --org "${INFLUX_ORG}"
)

if [[ "${FULL_RESTORE}" == true ]]; then
    INFLUX_RESTORE_ARGS+=(--full)
fi

INFLUX_RESTORE_ARGS+=("${SNAPSHOT_DIR}")

influx "${INFLUX_RESTORE_ARGS[@]}" 2>&1 | while IFS= read -r line; do log "  influx: ${line}"; done

echo ""
echo "============================================"
echo "  Restore Complete"
echo "============================================"
echo ""
log "InfluxDB at '${INFLUX_URL}' has been restored from: $(basename "${BACKUP_ZIP}")"
echo ""
