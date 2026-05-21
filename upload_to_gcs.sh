#!/bin/bash

# 1. Load variables from the .env file
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found!"
  exit 1
fi

# Export the credentials path so the system recognizes it
export GOOGLE_APPLICATION_CREDENTIALS="$GCP_ADC_PATH"

echo "Upload process is starting..."

# 2. Ingestr command
uvx ingestr ingest \
  --source-uri "csv://$LOCAL_CSV_PATH" \
  --source-table "transportation_data" \
  --dest-uri "gcs://?credentials_path=$GCP_ADC_PATH&project_id=$GOOGLE_CLOUD_PROJECT" \
  --dest-table "$BRONZE_BUCKET/hourly_transportation"

echo "Process completed!"