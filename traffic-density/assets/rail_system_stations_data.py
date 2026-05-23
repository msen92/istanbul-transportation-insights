"""@bruin
name: extract_rail_system_stations
image: python:3.11-slim
# We do NOT use 'materialization' here because we want to
# keep the raw files in GCS for our BigLake External Table.
@bruin"""

import json
import os
from datetime import datetime, timezone

import requests
from google.cloud import storage


CKAN_BASE_URL = "https://data.ibb.gov.tr/api/3/action"
DATASET_SLUG = "rayli-sistem-istasyon-noktalari-verisi"
DATASET_NAME = "rail_system_stations"


def get_required_env(name):
    value = os.getenv(name)

    if not value:
        raise ValueError(f"{name} environment variable is not set.")

    return value


def discover_resource_id():
    """
    Dataset sayfası:
    https://data.ibb.gov.tr/dataset/rayli-sistem-istasyon-noktalari-verisi

    Bu fonksiyon dataset içindeki datastore aktif resource_id değerini bulmaya çalışır.
    Eğer elle resource_id vermek istersen terminalde RAIL_RESOURCE_ID set edebilirsin.
    """

    manual_resource_id = os.getenv("RAIL_RESOURCE_ID")

    if manual_resource_id:
        print(f"Using resource_id from RAIL_RESOURCE_ID: {manual_resource_id}")
        return manual_resource_id

    package_show_url = f"{CKAN_BASE_URL}/package_show"

    response = requests.get(
        package_show_url,
        params={"id": DATASET_SLUG},
        timeout=60
    )

    print("Package show URL:", response.url)
    print("Package show status:", response.status_code)

    if response.status_code != 200:
        print("Package show response preview:")
        print(response.text[:1000])

    response.raise_for_status()

    payload = response.json()

    if not payload.get("success"):
        raise RuntimeError(f"CKAN package_show failed: {payload}")

    resources = payload.get("result", {}).get("resources", [])

    if not resources:
        raise RuntimeError("No resources found inside this dataset.")

    print("Resources found in dataset:")

    for index, resource in enumerate(resources, start=1):
        print(
            f"{index}. "
            f"name={resource.get('name')} | "
            f"id={resource.get('id')} | "
            f"format={resource.get('format')} | "
            f"datastore_active={resource.get('datastore_active')}"
        )

    for resource in resources:
        if resource.get("datastore_active") is True:
            selected_resource_id = resource.get("id")
            print(f"Selected datastore resource_id: {selected_resource_id}")
            return selected_resource_id

    raise RuntimeError(
        "This dataset has resources, but none of them has datastore_active=True. "
        "Open the dataset page, click the table/resource, copy the resource_id, "
        "then run: export RAIL_RESOURCE_ID=RESOURCE_ID"
    )


def fetch_batch(resource_id, limit, offset):
    datastore_url = f"{CKAN_BASE_URL}/datastore_search"

    response = requests.get(
        datastore_url,
        params={
            "resource_id": resource_id,
            "limit": limit,
            "offset": offset
        },
        timeout=60
    )

    print("Request URL:", response.url)
    print("Status code:", response.status_code)

    if response.status_code != 200:
        print("Response preview:")
        print(response.text[:1000])

    response.raise_for_status()

    payload = response.json()

    if not payload.get("success"):
        raise RuntimeError(f"CKAN datastore_search failed: {payload}")

    result = payload.get("result", {})

    records = result.get("records", [])
    total = result.get("total")

    return records, total


def upload_batch_to_gcs(bucket, records, resource_id, offset, ingested_at):
    """
    Aynı offset her çalışmada aynı dosyaya yazılır.
    Böylece tekrar çalıştırınca timestamp'li duplicate dosya üretmez.
    """

    blob_path = (
        f"{DATASET_NAME}/latest/"
        f"resource_id={resource_id}/"
        f"batch_offset={offset:012d}.ndjson"
    )

    blob = bucket.blob(blob_path)

    ndjson_lines = []

    for record in records:
        record["_source_resource_id"] = resource_id
        record["_source_dataset"] = DATASET_NAME
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

    return blob_path, len(records)


def run():
    bucket_name = get_required_env("BRONZE_BUCKET")
    resource_id = discover_resource_id()

    limit = int(os.getenv("BATCH_LIMIT", "1000"))
    offset = 0

    if limit <= 0:
        raise ValueError("BATCH_LIMIT must be greater than 0.")

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)

    ingested_at = datetime.now(timezone.utc).isoformat()

    print(f"Starting ingest for dataset={DATASET_NAME}")
    print(f"Resource ID: {resource_id}")
    print(f"Target bucket: gs://{bucket_name}/{DATASET_NAME}/latest/")
    print(f"Batch limit: {limit}")

    total_uploaded_rows = 0
    batch_number = 0

    while True:
        records, total = fetch_batch(
            resource_id=resource_id,
            limit=limit,
            offset=offset
        )

        if not records:
            print("No more records found.")
            break

        blob_path, uploaded_count = upload_batch_to_gcs(
            bucket=bucket,
            records=records,
            resource_id=resource_id,
            offset=offset,
            ingested_at=ingested_at
        )

        batch_number += 1
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

        if total is not None and offset >= total:
            break

    if total_uploaded_rows == 0:
        print("No data found.")
        return


        print(f"Successfully landed data in gs://{bucket_name}/rail_system_stations/")
    


