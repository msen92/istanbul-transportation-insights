"""@bruin
name: daily_total_passengers_chart
type: python
image: python:3.11-slim
description: "Bar chart for daily totals and a pie chart in the right corner for road type overview."
tags:
  - daily_total_passengers_chart
depends:
  - gold.may_daily_total_passengers
  - gold.may_daily_passengers_by_road_type
@bruin"""

from google.cloud import bigquery
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.ticker import StrMethodFormatter
import os

# 1. Initialize the BigQuery Client
client = bigquery.Client()

# --- DATA FETCHING STAGE ---

# First Data: Daily Total Passengers
table_id_1 = "datapsecta-bruin.gold.may_daily_total_passengers"
print(f"Fetching daily totals ({table_id_1}) from BigQuery...")
df_daily = client.list_rows(table_id_1).to_dataframe()
df_daily['DATE_TIME'] = pd.to_datetime(df_daily['DATE_TIME'])
df_daily = df_daily.sort_values(by='DATE_TIME')

# Second Data: Total Passengers by Road Type (Via SQL Query)
query_road_type = """
SELECT 
    road_type,
    SUM(total_passenger) AS total
FROM `datapsecta-bruin.gold.daily_passengers_by_road_type`
GROUP BY road_type
ORDER BY total DESC
"""
print("Fetching road type aggregated data from BigQuery...")
df_road = client.query(query_road_type).to_dataframe()


# --- CHART DRAWING STAGE ---

# Split the figure into two parts side-by-side (Left: Main Bar Chart, Right: Pie Chart)
# width_ratios=[3, 1] ensures the left side is 3 times wider than the right side
fig, (ax1, ax2) = plt.subplots(nrows=1, ncols=2, figsize=(20, 8), gridspec_kw={'width_ratios': [3, 1]}) 

# --- CHART 1 (LEFT): DAILY TOTAL NUMBER OF PASSENGERS (BAR CHART) ---
bars1 = ax1.bar(df_daily['DATE_TIME'], df_daily['TOTAL_PASSENGER'], color='cornflowerblue', edgecolor='black')

# Readability improvements (writing numbers vertically inside the bars)
ax1.bar_label(bars1, fmt='{:,.0f}', label_type='center', rotation=90, color='white', fontsize=11, fontweight='bold')
ax1.yaxis.set_major_formatter(StrMethodFormatter('{x:,.0f}'))

# Format X-axis dates
ax1.xaxis.set_major_locator(mdates.DayLocator())
ax1.xaxis.set_major_formatter(mdates.DateFormatter('%b %d')) 
ax1.tick_params(axis='x', rotation=45) 

# Set titles and labels for the bar chart
ax1.set_title('Daily Total Number of Passengers in May', fontsize=18, fontweight='bold', pad=15)
ax1.set_xlabel('Days of May', fontsize=14, fontweight='bold')
ax1.set_ylabel('Total Passengers', fontsize=14, fontweight='bold')
ax1.grid(True, axis='y', linestyle='--', alpha=0.7) 


# --- CHART 2 (RIGHT): MONTHLY SUMMARY BY ROAD TYPE (PIE CHART) ---
# Dynamic color assignment
# Note: We keep the Turkish database values ('RAYLI', 'DENİZ', 'OTOYOL') to ensure proper mapping.
custom_colors = []
for rt in df_road['road_type']:
    rt_str = str(rt).upper()
    if 'RAYLI' in rt_str:
        custom_colors.append('red')
    elif 'DENİZ' in rt_str or 'DENIZ' in rt_str:
        custom_colors.append('lightblue')
    elif 'OTOYOL' in rt_str:
        custom_colors.append("#6f433b")
    else:
        custom_colors.append('#1f77b4')

# Create the pie chart
# autopct='%1.1f%%' -> Calculates and adds percentages inside the chart
# startangle=140 -> Starts the slices from a more aesthetic angle
ax2.pie(
    df_road['total'], 
    labels=df_road['road_type'], 
    autopct='%1.1f%%', 
    startangle=140, 
    colors=custom_colors, 
    wedgeprops={'edgecolor': 'black', 'linewidth': 1},
    textprops={'fontsize': 12, 'fontweight': 'bold'}
)

ax2.set_title('Passenger Share by Road Type', fontsize=16, fontweight='bold', pad=15)

# Adjust layout so charts fit perfectly on the screen without overlapping
plt.tight_layout() 


# --- SAVING PROCESS ---
save_directory = "charts"

# Create the directory if it doesn't exist
os.makedirs(save_directory, exist_ok=True)

image_path = os.path.join(save_directory, "may_daily_total_passengers.png")

# Save the figure and clear the memory
plt.savefig(image_path, dpi=300, bbox_inches='tight') 
plt.close() 

print(f"Chart successfully saved to: {os.path.abspath(image_path)}")