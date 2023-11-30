#!/bin/bash

set -e 

: ${QUERY_NAME:="query"}
: ${LOKI_ADDR:="http://loki"}
: ${START_TIME:="yesterday 23:00"}
: ${END_TIME:="today 09:00"}
: ${GPG_RECIPIENT:="null"}
: ${S3_URL:="null"}
: ${MAX_ARCHIVE_SIZE:=509715200}
: ${GPG_PUBLIC_KEY_FILE:=/tmp/gpg_public_key.asc}
: ${PART_PATH_PREFIX:=/tmp/logcli}
: ${PARALLEL_MAX_WORKERS:=4}

LOGCLI_PATH="/usr/local/bin/logcli"
INPUT_TIME="$(date -d "$START_TIME" -u +%Y-%m-%dT%H:%M:%SZ)"
OUTPUT_TIME="$(date -d "$END_TIME" -u +%Y-%m-%dT%H:%M:%SZ)"

#functions

# Getting logs from Loki
get_logs () {
    "$LOGCLI_PATH"   query "$QUERY" --timezone=UTC --from="$1" --to="$2" --retries=3  --output=default --parallel-duration="1h" \
      --part-path-prefix="$PART_PATH_PREFIX" --merge-parts --parallel-max-workers="$PARALLEL_MAX_WORKERS" --quiet > "$3"
    # Check if logcli executed successfully
    if [ $? -eq 0 ]; then
        echo "Log scraping successful. Output saved to $3"
    else
        echo "Log scraping failed." >/dev/stderr
        exit 1
    fi
}

# Encrypting compressing and uploading the log file to s3 bucket
encrypt_compress_and_upload () {
    COMPRESSED_FILE="$1.xz"
    ENCRYPTED_FILE="$COMPRESSED_FILE.gpg"
    xz "$1"
    FILE_SIZE=$(wc -c <"$COMPRESSED_FILE")
    # Check if the archive file exists and has the correct XZ format
    if [ -f "$COMPRESSED_FILE" ]  && [ "$FILE_SIZE" -lt "$MAX_ARCHIVE_SIZE" ]; then # Remove xz --test "$COMPRESSED_FILE" 2>/dev/null
    gpg --trust-model always --output "$ENCRYPTED_FILE" --encrypt --recipient "$GPG_RECIPIENT" "$COMPRESSED_FILE"      #Add recepient as configurable
    else
        echo "Archive file doesn't exist or the size of archive($FILE_SIZE) is more than $MAX_ARCHIVE_SIZE bytes." >/dev/stderr
        exit 1;
    fi

    if aws s3 ls "$S3_URL" 2>/dev/null; then
            aws s3 cp "$ENCRYPTED_FILE"  "$S3_URL/${ENCRYPTED_FILE}"
    else
        echo "AWS S3 path doesn't exist." >/dev/stderr
        exit 1;
    fi
    echo "The archive was uploaded successfully to: $S3_URL/$ENCRYPTED_FILE"
    rm $COMPRESSED_FILE $ENCRYPTED_FILE 
}

# Get the difference in hours betweeen 2 dates
datediff () {
    d1=$(date -d "$1" '+%s')
    d2=$(date -d "$2" '+%s')
    echo $(($(($d2 - $d1)) / 3600))
}


QUERY="$1"
#Preliminary checks

if [ -z "$QUERY" ]; then
    echo "Logcli query is empty." >/dev/stderr
    exit 1
fi

if [[ -z "$GPG_PUBLIC_KEY_FILE" || ! -f "$GPG_PUBLIC_KEY_FILE" ]]; then
    echo "Public key file doesn't exist or is not specified." >/dev/stderr
    exit 1;
    
fi

gpg --import "$GPG_PUBLIC_KEY_FILE"

if ! [ -d "$(dirname "$PART_PATH_PREFIX")" ]; then
    echo "Path prefix doesn't exist." >/dev/stderr
    exit 1;
fi

DURATION=$(datediff "$INPUT_TIME" "$OUTPUT_TIME")

# Loop to cut the log window in smaller(4 hours) chunks.
while [[ $((DURATION - 4)) -gt -4 ]]
do
    if [[ $DURATION -gt 4 ]]; then
        OUTPUT_FILE="$(echo "$QUERY_NAME" | tr -d '\"\/_')_$(date -d "$INPUT_TIME" +%Y%m%dT%H%M%SZ)_$(date -d "$INPUT_TIME + 4 hours" +%Y%m%dT%H%M%SZ).log"
        get_logs "$INPUT_TIME" "$(date -d "$INPUT_TIME + 4 hours" -u +%Y-%m-%dT%H:%M:%SZ )" "$OUTPUT_FILE"
        encrypt_compress_and_upload "$OUTPUT_FILE"
        DURATION=$((DURATION-4))
        INPUT_TIME=$(date -d "$INPUT_TIME + 4 hours" -u +%Y-%m-%dT%H:%M:%SZ )
    else
        OUTPUT_FILE="$(echo "$QUERY_NAME" | tr -d '\"\/_')_$(date -d "$INPUT_TIME" +%Y%m%dT%H%M%SZ)_$(date -d "$OUTPUT_TIME" +%Y%m%dT%H%M%SZ).log"
        get_logs "$INPUT_TIME" "$OUTPUT_TIME" "$OUTPUT_FILE"
        encrypt_compress_and_upload "$OUTPUT_FILE"
    fi
done

