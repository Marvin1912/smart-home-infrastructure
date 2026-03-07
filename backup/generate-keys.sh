#!/usr/bin/env bash
#
# generate-keys.sh - Generate RSA key pair for database backup encryption
#
# Usage: ./generate-keys.sh [key_directory]
#
# Generates a 4096-bit RSA key pair used by backup.sh and restore.sh.
# The private key should be stored securely and NEVER committed to version control.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="${1:-${SCRIPT_DIR}/keys}"
KEY_SIZE=4096
PRIVATE_KEY="${KEY_DIR}/backup_private.pem"
PUBLIC_KEY="${KEY_DIR}/backup_public.pem"

echo "============================================"
echo "  RSA Key Pair Generator for DB Backup"
echo "============================================"
echo ""

# Check for openssl
if ! command -v openssl &>/dev/null; then
    echo "ERROR: openssl is not installed. Please install it first."
    exit 1
fi

# Create key directory if it doesn't exist
mkdir -p "${KEY_DIR}"

# Check if keys already exist
if [[ -f "${PRIVATE_KEY}" || -f "${PUBLIC_KEY}" ]]; then
    echo "WARNING: Key files already exist in ${KEY_DIR}:"
    [[ -f "${PRIVATE_KEY}" ]] && echo "  - ${PRIVATE_KEY}"
    [[ -f "${PUBLIC_KEY}" ]] && echo "  - ${PUBLIC_KEY}"
    echo ""
    read -rp "Overwrite existing keys? (y/N): " confirm
    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        echo "Aborted. Existing keys were not modified."
        exit 0
    fi
fi

echo "Generating ${KEY_SIZE}-bit RSA private key..."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:${KEY_SIZE} -out "${PRIVATE_KEY}" 2>/dev/null

echo "Extracting public key..."
openssl pkey -in "${PRIVATE_KEY}" -pubout -out "${PUBLIC_KEY}" 2>/dev/null

# Set restrictive permissions on private key
chmod 600 "${PRIVATE_KEY}"
chmod 644 "${PUBLIC_KEY}"

echo ""
echo "Keys generated successfully:"
echo "  Private key: ${PRIVATE_KEY} (mode: 600)"
echo "  Public key:  ${PUBLIC_KEY} (mode: 644)"
echo ""
echo "============================================"
echo "  IMPORTANT NOTES"
echo "============================================"
echo ""
echo "  1. The PRIVATE KEY is needed to DECRYPT/RESTORE backups."
echo "     Store it securely and NEVER commit it to version control."
echo ""
echo "  2. The PUBLIC KEY is needed to ENCRYPT/CREATE backups."
echo "     It can be safely distributed."
echo ""
echo "  3. To replace these example keys with your own:"
echo "     - Run this script again, or"
echo "     - Place your own .pem files in: ${KEY_DIR}"
echo ""
