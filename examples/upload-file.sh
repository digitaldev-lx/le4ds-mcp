#!/usr/bin/env bash
# Upload an image or PDF to le4ds with the presigned URL returned by `request_file_upload`.
#
# Usage:
#   ./upload-file.sh <file> <request_file_upload response JSON file>
#
# Then call `complete_file_upload` with the same `key`.
# Requires: bash, curl, jq.
set -euo pipefail

file="$1"
response="$2"

url=$(jq -r '.url' "$response")
content_type=$(jq -r '.headers["Content-Type"]' "$response")

curl -sS -f -X PUT --upload-file "$file" -H "Content-Type: $content_type" -o /dev/null "$url"

echo "Uploaded. key: $(jq -r '.key' "$response")"
