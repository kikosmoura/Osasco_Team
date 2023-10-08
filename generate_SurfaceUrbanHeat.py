# Import necessary libraries
import io
import ee
import folium
import geemap
import random
import time
import geopandas as gpd
from time import sleep
from progressbar import progressbar
import pandas as pd
import rasterio
import os
from scipy import stats
import seaborn as sns
import matplotlib.pyplot as plt
import rasterio

# Authenticate and initialize Earth Engine
ee.Authenticate()
ee.Initialize()

# Define the Earth Engine asset path
arq = 'projects/ee-kikosmoura/assets/sp_city_heat'
arq_modis = 'projects/ee-kikosmoura/assets/sp_city_heat_modis'



with rasterio.open(arq) as src1, rasterio.open(arq_modis) as src2:
    # Ler os dados raster em arrays numpy
    data1 = src1.read(1) 
    data2 = src2.read(1)  

   
    if data1.shape != data2.shape:
        raise ValueError("As dimensões dos arquivos não coincidem.")

   
    diff = data1 - data2
    print(diff)


# Read a shapefile into a GeoDataFrame
gdf = gpd.read_file('SIRGAS_SHP_distrito/SIRGAS_SHP_distrito.shp')

# Load an Earth Engine image
image = ee.Image(arq)

# Function to read shapefile and image
def read_files(arq):
    gdf = gpd.read_file('SIRGAS_SHP_distrito/SIRGAS_SHP_distrito.shp')
    image = ee.Image(arq)
    return gdf, image   

# Function to get soil carbon values
def get_carbono_solo(gdf, image):
    # Convert GeoDataFrame to Earth Engine FeatureCollection
    ee_fc = geemap.geopandas_to_ee(gdf)
    roi = ee.FeatureCollection(ee_fc).geometry()
    
    # Create an ImageCollection from the image and filter it by the ROI
    landsatCollection = ee.ImageCollection.fromImages([image])
    landsatCollection2 = landsatCollection.filterBounds(roi).map(lambda image: image.clip(roi))
    
    # Get the first image from the filtered collection
    listOfImages = landsatCollection2.toList(landsatCollection2.size())
    firstImage = listOfImages.get(0)
    firstImage = ee.Image(firstImage)
    
    # Reduce the region to compute the mean
    media = firstImage.reduceRegion(
        reducer=ee.Reducer.mean(),
        geometry=roi,
        scale=1000,  
        crs='EPSG:3310',  
        maxPixels=2e9
    )
    
    return media.getInfo()['b1'], media.getInfo()['b2']

# Read shapefile and image
arq = 'projects/ee-kikosmoura/assets/sp_city_heat'
gdf, image = read_files(arq)

# Initialize lists to store computed values
valores_media_dia = []
valores_media_noite = []

# Loop through the GeoDataFrame rows and compute values
for i in progressbar(range(0, len(gdf))):
    sleep(0.0001)
    resultado_media_dia, resultado_media_noite = get_carbono_solo(gdf.iloc[[i]], image)
    valores_media_dia.append(resultado_media_dia)
    valores_media_noite.append(resultado_media_noite)

# Create a DataFrame from the GeoDataFrame and computed values
df = pd.DataFrame(gdf)
df['valor_media_dia'] = valores_media_dia
df['valor_media_dia'] = round(df['valor_media_dia'], 2)
df['valor_media_noite'] = valores_media_noite
df['valor_media_noite'] = round(df['valor_media_noite'], 2)

# Select specific columns and save the DataFrame to a CSV file
df = df[['ds_codigo', 'ds_nome', 'ds_subpref', 'valor_media_dia', 'valor_media_noite', 'ds_areamt', 'ds_areakmt']]
df.to_csv('arquivo_sp_city_heat.csv', index=False)
