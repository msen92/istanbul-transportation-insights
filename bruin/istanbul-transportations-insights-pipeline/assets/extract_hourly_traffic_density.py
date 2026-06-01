"""@bruin
name: bronze.traffic_density
image: python:3.11-slim

tags:
  - bronze

secrets:
  - key: gcs-bronze
# We do NOT use 'materialization' here because we want to 
# keep the raw files in GCS for our BigLake External Table.
@bruin"""

from .scripts.download_ibb_data_as_csv import download,build_download_url,build_destination_url
import os
import json

vars = json.loads(os.environ.get("BRUIN_VARS"))

csv_url = build_download_url(vars["traffic_density"])
destination_url = build_destination_url(vars["traffic_density"])
bucket_name = json.loads(os.environ["gcs-bronze"])["bucket_name"]

download(csv_url,bucket_name,destination_url)