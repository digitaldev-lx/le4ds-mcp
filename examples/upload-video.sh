#!/usr/bin/env bash
# Upload a video to le4ds with the presigned multipart URLs returned by `request_video_upload`.
#
# Usage:
#   ./upload-video.sh <video.mp4> <request_video_upload response JSON file>
#
# Prints the `parts` array to pass to `complete_video_upload`.
# Requires: bash, curl, jq, split.
set -euo pipefail

video="$1"
response="$2"

part_size=$(jq -r '.part_size' "$response")
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

split -b "$part_size" -d -a 4 "$video" "$workdir/part-"

parts="[]"
index=0
for chunk in "$workdir"/part-*; do
    index=$((index + 1))
    url=$(jq -r --argjson n "$index" '.parts[] | select(.part_number == $n) | .url' "$response")
    etag=$(curl -sS -X PUT --upload-file "$chunk" -D - -o /dev/null "$url" \
        | tr -d '\r' | awk 'tolower($1) == "etag:" { print $2 }')
    if [ -z "$etag" ]; then
        echo "Part $index failed: no ETag returned" >&2
        exit 1
    fi
    parts=$(jq --argjson n "$index" --arg e "$etag" '. + [{part_number: $n, etag: $e}]' <<<"$parts")
    echo "Uploaded part $index" >&2
done

echo "$parts"
