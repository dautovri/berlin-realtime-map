#!/usr/bin/env bash
set -euo pipefail

# Berlin Transport Map — publish metadata to App Store Connect via asc CLI
APP_ID="6757723208"
FASTLANE_DIR="./fastlane"

echo "==> Fetching latest editable version..."
VERSION_ID=$(asc versions list --app "$APP_ID" --output json 2>/dev/null \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for v in data.get('data', []):
    state = v['attributes']['state']
    if state in ('PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED'):
        print(v['id'])
        sys.exit(0)
print(''); sys.exit(1)
")

if [[ -z "$VERSION_ID" ]]; then
  echo "Error: No editable version found (PREPARE_FOR_SUBMISSION or DEVELOPER_REJECTED)."
  exit 1
fi

echo "    Version ID: $VERSION_ID"

# Dry run first
echo "==> Dry run..."
ASC_TIMEOUT=180s asc migrate import \
  --app "$APP_ID" \
  --version-id "$VERSION_ID" \
  --fastlane-dir "$FASTLANE_DIR" \
  --dry-run --pretty

echo ""
read -rp "Proceed with upload? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

# Upload
echo "==> Uploading metadata..."
ASC_TIMEOUT=180s asc migrate import \
  --app "$APP_ID" \
  --version-id "$VERSION_ID" \
  --fastlane-dir "$FASTLANE_DIR" \
  --pretty

echo "==> Done."
