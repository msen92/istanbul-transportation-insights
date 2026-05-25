"""@bruin
name: daily_passengers_by_road_type_chart
type: python
image: python:3.11-slim
description: "Grouped bar chart showing daily passengers by road type with visible percentages."
tags:
  - daily_passengers_by_road_type_chart
depends:
  - gold.daily_passengers_by_road_type
@bruin"""

from google.cloud import bigquery
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter
import os

# 1. Initialize the BigQuery Client
client = bigquery.Client()

# 2. Define the exact table path 
table_id = "datapsecta-bruin.gold.daily_passengers_by_road_type"

# 3. Fetch the entire table directly and convert to DataFrame
print(f"Fetching entire table ({table_id}) from BigQuery...")
df = client.list_rows(table_id).to_dataframe()

# 4. Format data types and pivot the table
df['DATE_TIME'] = pd.to_datetime(df['DATE_TIME'])

# Satırlar: Tarihler | Sütunlar: Yol Tipleri | Değerler: Yolcu Sayısı
df_pivot = df.pivot_table(index='DATE_TIME', columns='ROAD_TYPE', values='TOTAL_PASSENGER', aggfunc='sum').fillna(0)
df_pivot = df_pivot.sort_index()

# 5. Create the Chart (Yan Yana Barlar için genişliği artırıyoruz)
fig, ax = plt.subplots(figsize=(24, 10)) 

# stacked=False parametresi barları üst üste değil YAN YANA dizer
df_pivot.plot(kind='bar', stacked=False, ax=ax, colormap='tab10', edgecolor='black', width=0.85)

# --- YÜZDELERİ HESAPLAMA VE YAZDIRMA ---
daily_totals = df_pivot.sum(axis=1)

# Grafikteki her bir yol tipini (renk grubunu) dönüyoruz
for i, container in enumerate(ax.containers):
    labels = []
    for j, bar in enumerate(container):
        height = bar.get_height()
        total_for_day = daily_totals.iloc[j]
        
        # Eğer o gün yolcu varsa yüzdeyi hesapla
        if height > 0 and total_for_day > 0:
            pct = (height / total_for_day) * 100
            # Sadece %1 ve üzeri payı olanlara yazı ekle (kalabalıktan kaçınmak için)
            if pct >= 1:
                labels.append(f'{pct:.0f}%')
            else:
                labels.append('')
        else:
            labels.append('')
            
    # Yüzdeleri barların hemen üstüne, 90 derece dik (okunaklı) şekilde ekle
    ax.bar_label(container, labels=labels, padding=5, rotation=90, fontsize=11, fontweight='bold')

# Y eksenindeki sayıları okunaklı yapıyoruz (örn: 1,000,000)
ax.yaxis.set_major_formatter(StrMethodFormatter('{x:,.0f}'))

# X eksenindeki tarihleri formatlıyoruz
formatted_dates = [dt.strftime('%b %d') for dt in df_pivot.index]
ax.set_xticklabels(formatted_dates, rotation=45, ha='right', fontsize=12)

# Lejantı (Road Type kutusunu) grafiğin sağ dışına alıyoruz
plt.legend(title='Road Type', bbox_to_anchor=(1.01, 1), loc='upper left', fontsize=12, title_fontsize=14)

# Genel Başlık ve Eksen İsimleri
plt.title('Daily Passenger Volume & Percentage by Road Type in May', fontsize=20, fontweight='bold', pad=20)
plt.xlabel('Days of May', fontsize=14, fontweight='bold')
plt.ylabel('Total Passengers', fontsize=14, fontweight='bold')

# Barların arkasına okumayı kolaylaştıran ızgara çizgileri ekle
plt.grid(True, axis='y', linestyle='--', alpha=0.5) 
plt.tight_layout() 

# --- KAYDETME İŞLEMİ (GÜNCELLENDİ) ---
# Kod 'traffic-density' içinde çalıştığı için doğrudan 'charts' klasörünü gösteriyoruz
save_directory = "charts"
os.makedirs(save_directory, exist_ok=True)

image_path = os.path.join(save_directory, "may_passengers_by_road_type.png")

plt.savefig(image_path, dpi=300, bbox_inches='tight') 
plt.close() 

print(f"Chart successfully saved to: {os.path.abspath(image_path)}")