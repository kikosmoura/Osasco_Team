// Import the image collection related to the Urban Heat Index from the Yale Center for Earth Observation.
var dataset = ee.ImageCollection('YALE/YCEO/UHI/UHI_yearly_pixel/v4');

// Import the MODIS image collection of land surface temperature for the year 2022 and filter by date.
var dataset_modis = ee.ImageCollection('MODIS/061/MOD11A2')
  .filter(ee.Filter.date('2022-01-01', '2022-12-31'));

// Select the daytime land surface temperature band from the MODIS images and define a color palette for visualization.
var landSurfaceTemperature = dataset_modis.select('LST_Day_1km');
var landSurfaceTemperatureVis = {
  min: 14000.0,
  max: 16000.0,
  palette: [
    '040274', '040281', '0502a3', '0502b8', '0502ce', '0502e6',
    '0602ff', '235cb1', '307ef3', '269db1', '30c8e2', '32d3ef',
    '3be285', '3ff38f', '86e26f', '3ae237', 'b5e22e', 'd6e21f',
    'fff705', 'ffd611', 'ffb613', 'ff8b13', 'ff6e08', 'ff500d',
    'ff0000', 'de0101', 'c21301', 'a71001', '911003'
  ],
};

// Set the map center and add the land surface temperature layer to the map.
Map.setCenter(6.746, 46.529, 2);
Map.addLayer(
    landSurfaceTemperature, landSurfaceTemperatureVis,
    'Land Surface Temperature');


// Define the region of interest (roi) as the geometry of a feature collection (table) and add it to the map.
var roi = ee.FeatureCollection(table).geometry();
Map.addLayer(roi);

// Filter and clip the urban heat index images to the region of interest (roi) and calculate the median.
var sp_city = dataset
  .filterBounds(roi)
  .map(function(image){return image.clip(roi)})
  .median();

// Filter and clip the MODIS images to the region of interest (roi) and calculate the median.
var sp_city_modis = landSurfaceTemperature
  .filterBounds(roi)
  .map(function(image){return image.clip(roi)})
  .median();

// Print the result to the console.
print(sp_city_modis);



// Print the result to the console.
print(sp_city);

// Define the visualization parameters for a specific band and adjust the map display.
var visualization = {
  bands: ['Daytime'],
  min: -1.5,
  max: 7.5,
  palette: [
    '313695', '74add1', 'fed976', 'feb24c', 'fd8d3c', 'fc4e2a', 'e31a1c',
    'b10026']
};


var visualization_modis = {
  bands: ['LST_Day_1km'],
  min: -1.5,
  max: 7.5,
  palette: [
    '040274', '040281', '0502a3', '0502b8', '0502ce', '0502e6',
    '0602ff', '235cb1', '307ef3', '269db1', '30c8e2', '32d3ef',
    '3be285', '3ff38f', '86e26f', '3ae237', 'b5e22e', 'd6e21f',
    'fff705', 'ffd611', 'ffb613', 'ff8b13', 'ff6e08', 'ff500d',
    'ff0000', 'de0101', 'c21301', 'a71001', '911003'
  ],
};


// Set the map center and add the urban heat index layer for São Paulo to the map.
Map.setCenter(-74.7, 40.6, 7);
Map.addLayer(sp_city, visualization, 'City of São Paulo');
Map.addLayer(sp_city_modis, visualization_modis, 'City of São Paulo');

// Export the resulting image from the analysis to Google Drive.
Export.image.toDrive({
  image: sp_city,
  description: 'sp_city_heat',
  scale: 1000,
  maxPixels: 2e10,
  region: roi
});

// Export the MODIS image to Google Drive.
Export.image.toDrive({
  image: sp_city_modis,
  description: 'sp_city_heat_modis',
  scale: 1000,
  maxPixels: 2e10,
  region: roi
});
