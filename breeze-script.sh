#!/bin/bash

# Define the base directory and log file
BASE_DIR="/home/master/applications"
LOG_FILE="/home/master/deactivation_log.txt"

# Initialize the log file
echo "Deactivation Log - $(date)" > "$LOG_FILE"

# Loop through each application folder
cd "$BASE_DIR" || { echo "Failed to navigate to $BASE_DIR"; exit 1; }
for APP in $(ls); do
  echo "Processing application: $APP" | tee -a "$LOG_FILE"

  # Navigate to public_html
  APP_DIR="$BASE_DIR/$APP/public_html"
  if [ -d "$APP_DIR" ]; then
    cd "$APP_DIR" || { echo "Failed to navigate to $APP_DIR" | tee -a "$LOG_FILE"; continue; }

    # Attempt to deactivate the Breeze plugin
    if wp plugin deactivate breeze --allow-root > /dev/null 2>&1; then
      echo "SUCCESS: Breeze plugin deactivated for $APP" | tee -a "$LOG_FILE"
    else
      echo "FAILED: Unable to deactivate Breeze plugin for $APP" | tee -a "$LOG_FILE"
    fi
  else
    echo "SKIPPED: $APP does not have a public_html directory" | tee -a "$LOG_FILE"
  fi

  # Return to the base directory
  cd "$BASE_DIR" || { echo "Failed to navigate back to $BASE_DIR"; exit 1; }
done

echo "Deactivation process completed. Log file: $LOG_FILE"
