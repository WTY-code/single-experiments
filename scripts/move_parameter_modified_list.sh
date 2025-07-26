#!/bin/bash

SOURCE_FILE="/root/ruc/experiments/config/parameters_to_modify.txt"

TARGET_DIR="/root/ruc/experiments/metrics"

# check source file
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file $SOURCE_FILE does not exist."
    exit 1
fi

# check target dir
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory $TARGET_DIR does not exist."
    exit 1
fi

# find the newest foloder named by timestamp
LATEST_DIR=$(ls "$TARGET_DIR" | grep -E '^[0-9]{8}_[0-9]{6}$' | sort -r | head -n 1)

# check if find the newest folder
if [ -z "$LATEST_DIR" ]; then
    echo "Error: No timestamped directories found in $TARGET_DIR."
    exit 1
fi

FULL_PATH="$TARGET_DIR/$LATEST_DIR"

# copy parameters_to_modify.txt to the metrics folder
cp "$SOURCE_FILE" "$FULL_PATH/"

# check if move successfully
if [ $? -eq 0 ]; then
    echo "Success: Moved $SOURCE_FILE to $FULL_PATH/"
else
    echo "Error: Failed to move $SOURCE_FILE to $FULL_PATH/"
    exit 1
fi