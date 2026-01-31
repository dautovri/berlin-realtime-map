#!/bin/bash

# Download all Berlin transport stops and save to app bundle
# Run this script before building to update the bundled stops data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/BerlinTransportMap/Resources/berlin_all_stops.json"

echo "Downloading all Berlin transport stops..."

# Create resources directory if needed
mkdir -p "$SCRIPT_DIR/BerlinTransportMap/Resources"

# Download stops in a grid pattern
ALL_STOPS=()
TEMP_DIR=$(mktemp -d)

# Berlin bbox: 52.34 to 52.68 lat, 13.08 to 13.76 lon
latStep=0.05 # ~5km
lonStep=0.08 # ~7km

for lat in $(seq 52.34 $latStep 52.68); do
    for lon in $(seq 13.08 $lonStep 13.76); do
        echo "Fetching stops near $lat, $lon..."
        curl -s "https://v6.vbb.transport.rest/locations/nearby?latitude=$lat&longitude=$lon&distance=8000&results=300&type=station" >> "$TEMP_DIR/stops_$$.json"
    done
done

# Combine and deduplicate
echo "Processing and deduplicating stops..."

# Use jq if available, otherwise use python
if command -v jq &> /dev/null; then
    cat "$TEMP_DIR/stops_$$.json" | jq -s 'flatten | unique_by(.id) | .' > "$OUTPUT_FILE"
else
    python3 -c "
import json
import sys
stops = []
for line in open('$TEMP_DIR/stops_$$.json'):
    line = line.strip()
    if line.startswith('[') or line.startswith('{'):
        try:
            data = json.loads(line)
            if isinstance(data, list):
                stops.extend(data)
            else:
                stops.append(data)
        except:
            pass

# Deduplicate by id
seen = set()
unique = []
for s in stops:
    sid = s.get('id')
    if sid and sid not in seen:
        seen.add(sid)
        unique.append(s)

with open('$OUTPUT_FILE', 'w') as f:
    json.dump(unique, f)
"
fi

# Cleanup
rm -rf "$TEMP_DIR"

STOP_COUNT=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_FILE'))))" 2>/dev/null || jq length "$OUTPUT_FILE")

echo "Saved $(echo $STOP_COUNT) stops to $OUTPUT_FILE"
echo "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
