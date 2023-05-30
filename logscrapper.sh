#!/bin/bash

set -e 
LOGCLI_PATH="/usr/local/bin/logcli" 
: ${LOKI_ADDR:="http://loki"} 
: ${INPUT_TIME:="yesterday 23:00"}
: ${OUTPUT_TIME:="today 09:00"}   
: ${GPG_RECIPIENT:="gpg@giosg.com"}
: ${S3_PATH:="bucket"}
OUTPUT_FILE="$(date --date='yesterday' '+%F').txt"
COMPRESSED_FILE="$OUTPUT_FILE.xz"
ENCRYPTED_FILE="$COMPRESSED_FILE.gpg"
: ${MAX_ARCHIVE_SIZE:=10485760}
: ${GPG_PUBLIC_KEY_PATH:=secrets/gpg_public_key.asc}
: ${PART_PATH_PREFIX:=/tmp/my_query}
: ${PARALLEL_MAX_WORKERS:=4}

#Preliminary checks

QUERY="$1" 

INPUT_TIME="$(date -d "$START_TIME" -u +%Y-%m-%dT%H:%M:%SZ)"
OUTPUT_TIME="$(date -d "$END_TIME" -u +%Y-%m-%dT%H:%M:%SZ)"

# Check if the logcli query is empty
if [ -z "$QUERY" ]; then
    echo "Logcli query is empty."
    exit 1
fi

if [[ -z "$GPG_PUBLIC_KEY_PATH" || ! -f "$GPG_PUBLIC_KEY_PATH" ]]; then
    echo "Public key file doesn't exist or is not specified."
    exit 1;
fi

gpg --import "$GPG_PUBLIC_KEY_PATH"

if [ -d "$(dirname "$PART_PATH_PREFIX")" ]; then
   FILENAME_PREFIX=$(echo "$QUERY" | tr -d '\"\/_')
    # Run logcli with the specified query and time range, and save the output to a file
    "$LOGCLI_PATH"   query "$QUERY" --timezone=UTC --from="$INPUT_TIME" --to="$OUTPUT_TIME"  --output=default --parallel-duration="5m" \
      --part-path-prefix="$PART_PATH_PREFIX" --merge-parts --parallel-max-workers="$PARALLEL_MAX_WORKERS" --quiet > "$OUTPUT_FILE"

    # Check if logcli executed successfully
    if [ $? -eq 0 ]; then
        echo "Log scraping successful. Output saved to $OUTPUT_FILE"
    else
        echo "Log scraping failed."
    fi

    xz "$OUTPUT_FILE"
    FILE_SIZE=$(wc -c <"$COMPRESSED_FILE")

    # Check if the archive file exists and has the correct XZ format
    if [ -f "$COMPRESSED_FILE" ]  && [ "$FILE_SIZE" -lt "$MAX_ARCHIVE_SIZE" ]; then # Remove xz --test "$COMPRESSED_FILE" 2>/dev/null
    gpg --trust-model always --output "$ENCRYPTED_FILE" --encrypt --recipient "$GPG_RECIPIENT" "$COMPRESSED_FILE"      #Add recepient as configurable
    else
        echo "Archive file doesn't exist or the size of archive is more than 10 MB"
        exit 1;
    fi

    if aws s3 ls "s3://$S3_PATH" 2>/dev/null; then
            aws s3 cp "$ENCRYPTED_FILE"  "s3://$S3_PATH/${FILENAME_PREFIX}_${ENCRYPTED_FILE}"
    else
        echo "AWS S3 bucket doesn't exist."
        exit 1;
    fi
    echo "The archive was uploaded successfully"
else
    echo "Path prefix doesn't exist."
    exit 1;
fi
