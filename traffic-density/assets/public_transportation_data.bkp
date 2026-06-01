"""@bruin
name: extract_hourly_transportation
image: python:3.11-slim
# We do NOT use 'materialization' here because we want to
# keep the raw files in GCS for our BigLake External Table.
@bruin"""

import requests
import json
from datetime import datetime, timezone
from google.cloud import storage
import os


def run():
    # 1. Configuration from .bruin.yml or Environment
    bucket_name = os.getenv("BRONZE_BUCKET")

    if not bucket_name:
        raise ValueError("BRONZE_BUCKET environment variable is not set.")

    resource_id = "857998e9-c051-4172-a988-757f03b1ac6c"
    base_url = "https://data.ibb.gov.tr/api/3/action/datastore_search"

    # 2. Fetching Logic with pagination
    limit = 1000
    offset = 0

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)

    ingested_at = datetime.now(timezone.utc).isoformat()

    print(f"Fetching hourly transportation data for resource_id={resource_id}...")
    print(f"Target bucket: gs://{bucket_name}")

    total_uploaded_rows = 0
    batch_number = 0

    while True:
        params = {
            "resource_id": resource_id,
            "limit": limit,
            "offset": offset
        }

        response = requests.get(base_url, params=params, timeout=60)
        response.raise_for_status()

        data = response.json()
        result = data.get("result", {})
        records = result.get("records", [])

        if not records:
            print("No more records found.")
            break

        # 3. Deterministic GCS path
        # Same offset writes to the same file.
        # This helps prevent duplicate files when the pipeline runs again.
        blob_path = (
            f"hourly_transportation/latest/"
            f"resource_id={resource_id}/"
            f"batch_offset={offset:012d}.ndjson"
        )

        blob = bucket.blob(blob_path)

        # 4. Convert current batch to NDJSON
        # We only keep one batch in memory.
        ndjson_lines = []

        for record in records:
            record["_source_resource_id"] = resource_id
            record["_source_dataset"] = "hourly_transportation"
            record["_batch_offset"] = offset
            record["_bruin_ingested_at"] = ingested_at

            ndjson_lines.append(
                json.dumps(record, ensure_ascii=False, default=str)
            )

        ndjson_content = "\n".join(ndjson_lines) + "\n"

        blob.upload_from_string(
            data=ndjson_content,
            content_type="application/x-ndjson"
        )

        batch_number += 1
        uploaded_count = len(records)
        total_uploaded_rows += uploaded_count

        print(
            f"Uploaded batch={batch_number}, "
            f"offset={offset}, "
            f"rows={uploaded_count}, "
            f"path=gs://{bucket_name}/{blob_path}"
        )

        if len(records) < limit:
            break

        offset += limit

    if total_uploaded_rows == 0:
        print("No data found.")
        return

    print(
        f"Successfully landed {total_uploaded_rows} rows "
        f"in gs://{bucket_name}/hourly_transportation/latest/"
    )


if __name__ == "__main__":
    run()