"""@bruin
name: bronze.rail_system_stats
image: python:3.11-slim

tags:
  - bronze
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
    resource_id = "f0efe978-7451-40d4-a03e-d8d7b992ae78"
    base_url = f"https://data.ibb.gov.tr/api/3/action/datastore_search?resource_id={resource_id}"
    
    # 2. Fetching Logic (with pagination)
    limit = 1000
    offset = 0
    all_records = []
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Baslatiliyor: Veri cekme islemi ({resource_id})...")
    
    while True:
        url = f"{base_url}&limit={limit}&offset={offset}"
        
        try:
            response = requests.get(url, timeout=30) # Takılmaları önlemek için timeout eklendi
            response.raise_for_status()
            data = response.json()
        except Exception as e:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] HATA: istek basarisiz oldu. Offset: {offset}. Detay: {e}")
            break
            
        result = data.get("result", {})
        records = result.get("records", [])
        total_expected = result.get("total", "Bilinmiyor") # Veri setinin toplam büyüklüğü
        
        # Eğer kayıt dönmediyse tüm veriler çekilmiş demektir, döngüden çık.
        if not records: 
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Veri çekme islemi tamamlandı. Baska kayit kalmadi.")
            break
            
        all_records.extend(records)
        
        # Ekrandan ilerlemeyi takip edebilmek için log
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ilerleme: {len(all_records)} / {total_expected} kayit basariyla cekildi.")
        
        # Bir sonraki sayfa için offset'i gerçekte çekilen kayıt sayısı kadar artırıyoruz
        offset += len(records)

    if not all_records:
        print("Hic veri bulunamadi veya cekilemedi.")
        return

    # 3. Convert to Newline Delimited JSON
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Veriler NDJSON formatina donusturuluyor...")
    nd_json_content = "\n".join([json.dumps(record) for record in all_records])

    # 4. Upload to the Bucket
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Google Cloud Storage'a yukleniyor...")
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    blob = bucket.blob(f"rail_system_stats/load_{timestamp}.json")
    
    blob.upload_from_string(
        data=nd_json_content,
        content_type='application/x-ndjson'
    )
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] BASARILI: {len(all_records)} kayit gs://{bucket_name}/rail_system_stats/ dizinine yüklendi.")

if __name__ == "__main__":
    run()
    print("deactived")
