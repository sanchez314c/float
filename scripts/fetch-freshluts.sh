#!/bin/bash
# fetch-freshluts.sh — Download all free LUTs from freshluts.com via their public S3 bucket
# License: All LUTs on freshluts.com are CC0 (free for commercial use, no attribution)
#
# Usage:
#   ./fetch-freshluts.sh                    # Downloads to ~/Luts/freshluts/
#   ./fetch-freshluts.sh /path/to/folder    # Downloads to specified folder

S3_BUCKET="https://s3.us-east-2.amazonaws.com/freshluts"
S3_PREFIX="luts/lutfiles/"
OUTPUT_DIR="${1:-$HOME/Luts/freshluts}"
MAX_KEYS=1000
PARALLEL_DOWNLOADS=8

mkdir -p "$OUTPUT_DIR"

echo "=== FreshLUTs Downloader ==="
echo "Output: $OUTPUT_DIR"
echo ""

# Phase 1: Enumerate all LUT files from S3 bucket listing
echo "Scanning S3 bucket for LUT files..."

all_keys_file=$(mktemp)
continuation_token=""
total_found=0

while true; do
    url="${S3_BUCKET}/?list-type=2&prefix=${S3_PREFIX}&max-keys=${MAX_KEYS}"
    if [ -n "$continuation_token" ]; then
        # URL-encode the continuation token
        encoded_token=$(printf '%s' "$continuation_token" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=''))")
        url="${url}&continuation-token=${encoded_token}"
    fi

    response=$(curl -s "$url")

    # Extract file keys (paths) from XML response
    echo "$response" | grep -oP '<Key>[^<]+</Key>' | sed 's/<Key>//;s/<\/Key>//' >> "$all_keys_file"

    page_count=$(echo "$response" | grep -oP '<Key>[^<]+</Key>' | wc -l)
    total_found=$((total_found + page_count))
    echo "  Found $total_found files so far..."

    # Check if there are more results
    is_truncated=$(echo "$response" | grep -oP '<IsTruncated>[^<]+</IsTruncated>' | sed 's/<[^>]*>//g')
    if [ "$is_truncated" != "true" ]; then
        break
    fi

    # Get next continuation token
    continuation_token=$(echo "$response" | grep -oP '<NextContinuationToken>[^<]+</NextContinuationToken>' | sed 's/<[^>]*>//g')
    if [ -z "$continuation_token" ]; then
        break
    fi
done

# Filter to only .cube and .3dl files
lut_keys_file=$(mktemp)
grep -iE '\.(cube|3dl)$' "$all_keys_file" > "$lut_keys_file"
total_luts=$(wc -l < "$lut_keys_file")

echo ""
echo "Found $total_luts LUT files to download."
echo ""

if [ "$total_luts" -eq 0 ]; then
    echo "No LUT files found. Exiting."
    rm -f "$all_keys_file" "$lut_keys_file"
    exit 1
fi

# Phase 2: Download all LUT files
downloaded=0
skipped=0
failed=0

download_lut() {
    local key="$1"
    local filename=$(basename "$key")
    local dest="$OUTPUT_DIR/$filename"

    # Handle duplicate filenames by prepending the LUT ID
    if [ -f "$dest" ]; then
        local lut_id=$(echo "$key" | grep -oP '\d{3}/\d{3}/\d{3}' | tr -d '/')
        dest="$OUTPUT_DIR/${lut_id}_${filename}"
    fi

    if [ -f "$dest" ]; then
        echo "SKIP $filename (already exists)"
        return 2
    fi

    local url="${S3_BUCKET}/${key}"
    if curl -sf -o "$dest" "$url"; then
        echo "  OK  $filename"
        return 0
    else
        echo "FAIL $filename"
        rm -f "$dest"
        return 1
    fi
}

export -f download_lut
export S3_BUCKET OUTPUT_DIR

# Use xargs for parallel downloads
cat "$lut_keys_file" | xargs -P "$PARALLEL_DOWNLOADS" -I{} bash -c 'download_lut "$@"' _ {}

# Count results
final_count=$(find "$OUTPUT_DIR" -type f \( -iname "*.cube" -o -iname "*.3dl" \) | wc -l)

echo ""
echo "=== COMPLETE ==="
echo "$final_count LUT files in: $OUTPUT_DIR"
echo ""
echo "To use with float:"
echo "  1. Edit ~/.config/float/settings.conf and set: lut_dir=$OUTPUT_DIR"
echo "  2. Or run: float /path/to/videos --luts $OUTPUT_DIR"

# Cleanup
rm -f "$all_keys_file" "$lut_keys_file"
