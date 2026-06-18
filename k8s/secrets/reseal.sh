#!/usr/bin/env bash
# Add or update a single key in an existing SealedSecret JSON file without
# unsealing the keys already present.
#
# Usage:
#   ./reseal.sh <secret-file.json> <KEY> <VALUE>
#   echo -n "value" | ./reseal.sh <secret-file.json> <KEY> -
#
# Requires kubeseal + the cluster's public cert at repo root (sealed-secret.crt).
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <secret-file.json> <KEY> <VALUE|->" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT="$SCRIPT_DIR/../../sealed-secret.crt"
SECRET_FILE="$1"
KEY="$2"
VALUE="$3"

if [[ "$VALUE" == "-" ]]; then
  VALUE="$(cat)"
fi

NAME=$(python3 -c "import json; print(json.load(open('$SECRET_FILE'))['metadata']['name'])")
NAMESPACE=$(python3 -c "import json; print(json.load(open('$SECRET_FILE'))['metadata']['namespace'])")

ENCRYPTED=$(printf '%s' "$VALUE" | kubeseal --raw \
  --cert "$CERT" \
  --namespace "$NAMESPACE" \
  --name "$NAME" \
  --scope cluster-wide \
  --from-file=/dev/stdin)

python3 - "$SECRET_FILE" "$KEY" "$ENCRYPTED" <<'PYEOF'
import json
import sys

path, key, encrypted = sys.argv[1:4]
with open(path) as f:
    data = json.load(f)
data["spec"]["encryptedData"][key] = encrypted
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF

echo "Updated $KEY in $SECRET_FILE"
