// Load an Earth Engine ImageCollection named 'dataset' from a specified source
var dataset = ee.ImageCollection('YALE/YCEO/UHI/UHI_yearly_pixel/v4');

// Load a region of interest (ROI) as a FeatureCollection and add it as a layer to the map
var roi = ee.FeatureCollection(table).geometry();
Map.addLayer(roi);

// Filter the 'dataset' ImageCollection to only include images that intersect with the ROI,
// clip each image to the ROI, and then calculate the median of the clipped images.
var sp_city = dataset
  .filterBounds(roi)
  .map(function(image) {
    return image.clip(roi);
  })
  .median();

// Define visualization parameters for the 'sp_city' image
var visualization = {
  bands: ['Daytime'],  // Specify the band to visualize
  min: -1.5,           // Minimum pixel value for color mapping
  max: 7.5,            // Maximum pixel value for color mapping
  palette: [            // Define a color palette for visualization
    '313695', '74add1', 'fed976', 'feb24c', 'fd8d3c', 'fc4e2a', 'e31a1c', 'b10026'
  ]
};

// Set the map center and zoom level
Map.setCenter(-74.7, 40.6, 7);

// Add the 'sp_city' image as a layer to the map with the specified visualization parameters
Map.addLayer(sp_city, visualization, 'Cidade de Sao Paulo');

// Add the entire 'dataset' as a layer to the map with the same visualization parameters
Map.addLayer(dataset, visualization, 'Daytime UHI');

// Export the 'sp_city' image to Google Drive with specified export options
Export.image.toDrive({
  image: sp_city,         // Image to export
  description: 'sp_city_heat',  // Description for the exported file
  scale: 1000,            // Resolution in meters per pixel
  maxPixels: 2e10,        // Maximum number of pixels to export
  region: roi             // Export region, which is the defined ROI
});
