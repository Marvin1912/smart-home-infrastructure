#!/usr/bin/env bash
#
# backup.sh - Encrypted InfluxDB backup
#
# Creates a full InfluxDB snapshot (all buckets, metadata, tasks, etc.),
# compresses it, encrypts it using hybrid RSA+AES encryption, and packages
# it as a zip file.
#
# Usage: ./backup.sh [--output-dir DIR] [--public-key PATH] [--watch-dir DIR]
#
# Environment Variables:
#   INFLUX_URL    - InfluxDB URL (default: http://localhost:8086)
#   INFLUX_TOKEN  - InfluxDB API token with read access (REQUIRED)
#   INFLUX_ORG    - InfluxDB organization name (default: wildfly_domain)
#   INFLUX_BUCKET - Specific bucket to back up (default: all buckets)
#   BACKUP_DIR    - Output directory for backups (default: ./backups)
#   PUBLIC_KEY    - Path to RSA public key (default: ./keys/backup_public.pem)
#   WATCH_DIR     - Directory to atomically move the final zip into (optional)

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

INFLUX_URL="${INFLUX_URL:-http://localhost:8086}"
INFLUX_ORG="${INFLUX_ORG:-wildfly_domain}"
INFLUX_BUCKET="${INFLUX_BUCKET:-}"

if [[ -z "${INFLUX_TOKEN:-}" ]]; then
    echo "ERROR: INFLUX_TOKEN environment variable is required but not set."
    echo "Provide an InfluxDB API token with read access."
    exit 1
fi

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
            echo "  --watch-dir   Directory to atomically move the final zip into"
            echo ""
            echo "Environment Variables:"
            echo "  INFLUX_URL    InfluxDB URL (default: http://localhost:8086)"
            echo "  INFLUX_TOKEN  InfluxDB API token with read access (REQUIRED)"
            echo "  INFLUX_ORG    InfluxDB organization name (default: wildfly_domain)"
            echo "  INFLUX_BUCKET Specific bucket to back up (default: all buckets)"
            echo "  BACKUP_DIR    Output directory (default: ./backups)"
            echo "  PUBLIC_KEY    RSA public key path (default: ./keys/backup_public.pem)"
            echo "  WATCH_DIR     Watch directory for atomic move (optional)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# File naming
SNAPSHOT_DIR="${BACKUP_DIR}/influxdb_snapshot_${TIMESTAMP}"
ARCHIVE_FILE="${BACKUP_DIR}/influxdb_${TIMESTAMP}.tar.gz"
ENCRYPTED_FILE="${ARCHIVE_FILE}.enc"
AES_KEY_FILE="${BACKUP_DIR}/aes_key_${TIMESTAMP}.bin"
ENCRYPTED_KEY_FILE="${AES_KEY_FILE}.enc"
FINAL_ZIP="${BACKUP_DIR}/influxdb_backup_${TIMESTAMP}.zip"

# ============================================================================
# Functions
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "${SNAPSHOT_DIR}" 2>/dev/null || true
    rm -f "${ARCHIVE_FILE}" "${ENCRYPTED_FILE}" \
          "${AES_KEY_FILE}" "${ENCRYPTED_KEY_FILE}" 2>/dev/null || true
}

trap cleanup EXIT

check_prerequisites() {
    local missing=()

    for cmd in influx openssl tar zip; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR: Missing required tools: ${missing[*]}"
        log "Install influx CLI from https://docs.influxdata.com/influxdb/v2/tools/influx-cli/"
        log "Install others with: sudo apt-get install openssl tar zip"
        exit 1
    fi
}

validate_public_key() {
    if [[ ! -f "${PUBLIC_KEY}" ]]; then
        log "ERROR: RSA public key not found at: ${PUBLIC_KEY}"
        log "Generate keys first: ../backup/generate-keys.sh ./keys"
        exit 1
    fi

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
echo "  Encrypted InfluxDB Backup"
echo "============================================"
echo ""

log "Starting backup process..."
log "InfluxDB: ${INFLUX_URL} (org: ${INFLUX_ORG})"
if [[ -n "${INFLUX_BUCKET}" ]]; then
    log "Bucket:   ${INFLUX_BUCKET}"
else
    log "Bucket:   all buckets"
fi

# Step 0: Check prerequisites
check_prerequisites
validate_public_key

mkdir -p "${BACKUP_DIR}"

# Step 1: Create InfluxDB snapshot
log "Step 1/6: Creating InfluxDB snapshot..."

INFLUX_BACKUP_ARGS=(
    backup
    --host "${INFLUX_URL}"
    --token "${INFLUX_TOKEN}"
    --org "${INFLUX_ORG}"
)

if [[ -n "${INFLUX_BUCKET}" ]]; then
    INFLUX_BACKUP_ARGS+=(--bucket "${INFLUX_BUCKET}")
fi

INFLUX_BACKUP_ARGS+=("${SNAPSHOT_DIR}")

influx "${INFLUX_BACKUP_ARGS[@]}" 2>&1 | while IFS= read -r line; do log "  influx: ${line}"; done

if [[ ! -d "${SNAPSHOT_DIR}" ]] || [[ -z "$(ls -A "${SNAPSHOT_DIR}")" ]]; then
    log "ERROR: InfluxDB snapshot failed or produced empty directory"
    exit 1
fi

SNAPSHOT_SIZE=$(du -sh "${SNAPSHOT_DIR}" | cut -f1)
log "  Snapshot size: ${SNAPSHOT_SIZE}"

# Step 2: Compress the snapshot into a tar archive
log "Step 2/6: Compressing snapshot with tar+gzip..."
tar czf "${ARCHIVE_FILE}" -C "${BACKUP_DIR}" "influxdb_snapshot_${TIMESTAMP}"

ARCHIVE_SIZE=$(du -h "${ARCHIVE_FILE}" | cut -f1)
log "  Archive size: ${ARCHIVE_SIZE}"

# Step 3: Generate a random AES-256 key
log "Step 3/6: Generating random AES-256 key..."
openssl rand 32 > "${AES_KEY_FILE}"

# Step 4: Encrypt the archive with AES-256-CBC
log "Step 4/6: Encrypting data with AES-256-CBC..."
openssl enc -aes-256-cbc \
    -salt \
    -pbkdf2 \
    -iter 100000 \
    -in "${ARCHIVE_FILE}" \
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

ARCHIVE_DATA_NAME="influxdb_${TIMESTAMP}.tar.gz.enc"
ARCHIVE_KEY_NAME="influxdb_${TIMESTAMP}.key.enc"

cp "${ENCRYPTED_KEY_FILE}" "${BACKUP_DIR}/${ARCHIVE_KEY_NAME}"

(cd "${BACKUP_DIR}" && zip -j "${FINAL_ZIP}" "${ARCHIVE_DATA_NAME}" "${ARCHIVE_KEY_NAME}")

rm -f "${BACKUP_DIR}/${ARCHIVE_DATA_NAME}" "${BACKUP_DIR}/${ARCHIVE_KEY_NAME}"

FINAL_SIZE=$(du -h "${FINAL_ZIP}" | cut -f1)

echo ""
echo "============================================"
echo "  Backup Complete"
echo "============================================"
echo ""
log "Output file: ${FINAL_ZIP}"
log "File size:   ${FINAL_SIZE}"
log "InfluxDB:    ${INFLUX_URL} (org: ${INFLUX_ORG})"
log "Timestamp:   ${TIMESTAMP}"
echo ""
echo "To restore this backup, run:"
echo "  ./restore.sh ${FINAL_ZIP}"
echo ""

# Optional: Atomically move the backup to a watch directory
if [[ -n "${WATCH_DIR}" ]]; then
    log "Moving backup to watch directory: ${WATCH_DIR}"
    mkdir -p "${WATCH_DIR}"
    mv "${FINAL_ZIP}" "${WATCH_DIR}/$(basename "${FINAL_ZIP}")"
    log "Backup moved to: ${WATCH_DIR}/$(basename "${FINAL_ZIP}")"
fi
