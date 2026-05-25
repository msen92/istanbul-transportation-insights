
import requests
from requests.adapters import HTTPAdapter
from urllib3.util import Retry
from google.cloud import storage
from collections import deque
import threading
import time

def create_resilient_session():
    session = requests.Session()
    
    retries = Retry(
        total=5,
        backoff_factor=2,
        status_forcelist=[500, 502, 503, 504],
        raise_on_status=False
    )
    
    adapter = HTTPAdapter(max_retries=retries)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    
    return session

def build_download_url(bruin_params):
    dataset_id = bruin_params["dataset_id"]
    resource_id = bruin_params["resource_id"]
    file_name = bruin_params["file_name"]
    url_base = f"https://data.ibb.gov.tr/dataset/{dataset_id}/resource/{resource_id}/download/{file_name}"
    return url_base

def build_destination_url(bruin_params):
    file_name = bruin_params["file_name"]
    name_without_extention = file_name.split(".")[0]
    parts = name_without_extention.split("_")
    name = "_".join(parts[:-1])
    month = parts[-1]
    return f"{name}/{month[0:4]}-{month[4:6]}/{name}.csv"

def add_csv_chunks_to_queue(chunk_queue,url,chunk_size):
    session = create_resilient_session()
    with session.get(url, stream=True, timeout=600) as response:
        try:
            response.raise_for_status()
            total_downloaded_size = 0
            for chunk in response.iter_content(chunk_size=chunk_size): # Increased chunk size slightly
                chunk_queue.append(chunk)
                total_downloaded_size += chunk_size
                print(f"Dowloaded size: {total_downloaded_size}")
        except requests.exceptions.ChunkedEncodingError as e:
            print(f"\n[Warning] Connection interrupted by server, attempting to recover... Error: {e}")
            raise e

def upload_chunks_to_gcs(chunk_queue,blob,chunk_size = 2621440):
    print("upload started")
    total_uploaded_size = 0
    with blob.open("wb",chunk_size=chunk_size) as f:
        while chunk_queue:
            f.write(chunk_queue.popleft())
            total_uploaded_size += chunk_size
            print(f"Uploaded size: {total_uploaded_size}")
        print("Upload complete successfully!")

def download(csv_url,bucket_name,destination_file_name,chunk_size = 2621440):
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_file_name)

    chunk_queue = deque()

    thread1 = threading.Thread(target=add_csv_chunks_to_queue, args=(chunk_queue,csv_url,chunk_size))
    thread2 = threading.Thread(target=upload_chunks_to_gcs, args=(chunk_queue,blob,chunk_size))

    thread1.start()
    while not chunk_queue:
        time.sleep(1)
        print("Waiting for download to start")
    thread2.start()
    
    thread1.join()
    thread2.join()
