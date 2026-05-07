"""@bruin
name: extract_hourly_traffic_density
image: python:3.11-slim
# We do NOT use 'materialization' here because we want to 
# keep the raw files in GCS for our BigLake External Table.
@bruin"""

import requests
import json
from datetime import datetime
from google.cloud import storage
import os

def run():
    # 1. Configuration from .bruin.yml or Environment
    bucket_name = os.getenv("BRONZE_BUCKET")
    resource_id = "516997a4-d03d-4272-9fd3-ec307e9e4a91"
    base_url = f"https://data.ibb.gov.tr/api/3/action/datastore_search?resource_id={resource_id}"
    
    # 2. Fetching Logic (with pagination)
    limit = 1000
    offset = 0
    all_records = []
    
    print(f"Fetching data for {resource_id}...")
    while True:
        url = f"{base_url}&limit={limit}&offset={offset}"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        records = data.get("result", {}).get("records", [])
        
        if not records: break
        all_records.extend(records)
        if len(records) < limit: break
        offset += limit

    if not all_records:
        print("No data found.")
        return

    # 3. Convert to Newline Delimited JSON
    # This is critical for the BigLake table we defined in Terraform
    nd_json_content = "\n".join([json.dumps(record) for record in all_records])

    # 4. Upload to the Bucket
    # We use a timestamped filename so we have a history of loads (Immutable Bronze)
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    blob = bucket.blob(f"traffic_density/load_{timestamp}.json")
    
    blob.upload_from_string(
        data=nd_json_content,
        content_type='application/x-ndjson'
    )
    
    print(f"Successfully landed data in gs://{bucket_name}/traffic_density/")

if __name__ == "__main__":
    run()