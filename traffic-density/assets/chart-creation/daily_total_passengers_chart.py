"""@bruin
name: daily_total_passengers_chart
type: python
image: python:3.11-slim
description: "Bar chart showing the daily total number of passengers in May, reading directly from the gold table and saving to a relative local directory."
tags:
  - daily_total_passengers_chart
depends:
  - gold.daily_total_passengers
@bruin"""

from google.cloud import bigquery
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.ticker import StrMethodFormatter
import os

# 1. Initialize the BigQuery Client
client = bigquery.Client()

# 2. Define the exact table path (No SQL needed)
table_id = "datapsecta-bruin.gold.daily_total_passengers"

# 3. Fetch the entire table directly and convert to DataFrame
print(f"Fetching entire table ({table_id}) from BigQuery...")
df = client.list_rows(table_id).to_dataframe()

# 4. Format the data types and sort by date 
df['DATE_TIME'] = pd.to_datetime(df['DATE_TIME'])
df = df.sort_values(by='DATE_TIME')

# 5. Create the Chart
fig, ax = plt.subplots(figsize=(16, 8)) 

# Draw a bar chart
bars = ax.bar(df['DATE_TIME'], df['TOTAL_PASSENGER'], color='cornflowerblue', edgecolor='black')

# --- IMPROVEMENTS FOR READABILITY ---
ax.bar_label(bars, fmt='{:,.0f}', label_type='center', rotation=90, color='white', fontsize=11, fontweight='bold')
ax.yaxis.set_major_formatter(StrMethodFormatter('{x:,.0f}'))

ax.xaxis.set_major_locator(mdates.DayLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %d')) 
plt.xticks(rotation=45) 

# Add title and axis labels 
plt.title('Daily Total Number of Passengers in May', fontsize=16, fontweight='bold')
plt.xlabel('Days of May', fontsize=14, fontweight='bold')
plt.ylabel('Total Passengers', fontsize=14, fontweight='bold')

plt.grid(True, axis='y', linestyle='--', alpha=0.7) 
plt.tight_layout() 

# --- KAYDETME İŞLEMİ (GÜNCELLENDİ) ---
# Kod 'traffic-density' içinde çalıştığı için doğrudan 'charts' klasörünü gösteriyoruz
save_directory = "charts"

# Eğer belirtilen klasör yoksa otomatik oluşturur
os.makedirs(save_directory, exist_ok=True)

# Klasör yolu ile dosya adını birleştirir
image_path = os.path.join(save_directory, "may_daily_passengers.png")

# Resmi kaydet ve belleği temizle
plt.savefig(image_path, dpi=300, bbox_inches='tight') 
plt.close() 

# İşlemin başarılı olduğunu ve dosyanın tam yolunu konsola yazdır
print(f"Chart successfully saved to: {os.path.abspath(image_path)}")