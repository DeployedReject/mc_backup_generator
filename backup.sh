#!/bin/bash

# --- Variables ---
SOURCE_FOLDER="world"
TARGET_FOLDER="backup"
LOG_FILE="backup.log"
STATUS_FILE="backup.status.log"
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")

# --- Main Logic ---
trap './svctrl.sh -mc save-on' EXIT

# [ -d ... ] checks if the path exists and is a directory
if [ -d "$SOURCE_FOLDER" ]; then
  echo "Success: The folder '$SOURCE_FOLDER' exists in the current directory." | tee -a "$LOG_FILE" >"$STATUS_FILE"
  #--Preventing race condition.
  ./svctrl.sh -mc save-all
  ./svctrl.sh -mc save-off
  #--Checking if this is the first time the backup is being made
  mkdir -p "$TARGET_FOLDER"
  mkdir "$TARGET_FOLDER/$TIMESTAMP.backup"

  cp -r "$SOURCE_FOLDER/." "$TARGET_FOLDER/$TIMESTAMP.backup"

  COUNT=$(ls -1d "$TARGET_FOLDER"/*.backup 2>/dev/null | wc -l)
  if [ "$COUNT" -gt 3 ]; then
    OLDEST=$(ls -1d "$TARGET_FOLDER"/*.backup 2>/dev/null | sort | head -n 1)
    rm -rf "$OLDEST"
    echo "Deleted $OLDEST (Total: $COUNT)" | tee -a "$LOG_FILE" >>"$STATUS_FILE"
  fi

  rclone sync "$TARGET_FOLDER" gdrive:"$TARGET_FOLDER"

else
  echo "Error: Could not find a folder named '$SOURCE_FOLDER'." >>"$LOG_FILE"
  echo "Current directory contents:"
  ls -F
  exit 1
fi

exit 0
