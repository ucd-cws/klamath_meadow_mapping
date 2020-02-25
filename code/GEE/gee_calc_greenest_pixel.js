var huc10 = ee.FeatureCollection("users/rapeek/HUC10Watersheds_FocusArea"),
    roi = /* color: #d63000 */ee.Geometry.Point([-122.72278395403117, 41.32239158947847]);
    


// import NAIP imagery
var naipIMGs = ee.ImageCollection('USDA/NAIP/DOQQ') 
            .filter(ee.Filter.date('2015-01-01', '2018-12-31'))
            .filterBounds(huc10);

var naip = function(image) {
  return image.clip(huc10); 
};

var naip2 = naipIMGs.map(naip);

// select bands (RBG, not near infrared)
var naipColor = naip2.select(['R', 'G', 'B']);
var naipColorVis = {
  min: 0.0,
  max: 255.0,
};

// Now map
Map.centerObject(huc10);
Map.addLayer(naipColor, naipColorVis, 'NAIP');
Map.addLayer(huc10, {},'H10');


// Get LSAT8
var l8 = ee.ImageCollection('LANDSAT/LC08/C01/T1_TOA')
  .filterBounds(huc10);


// get the least cloudy image in 2018
var image = ee.Image(
    l8.filterBounds(huc10)
    .filterDate('2016-05-01', '2018-10-31')
    .sort('CLOUD_COVER')
    .first()
);

// Compute the Normalized Difference Vegetation Index (NDVI).
var ndvi18 = image.normalizedDifference(['B5', 'B4']).rename('NDVI');

// Display the result for single least cloudy
var ndviParams = {min: -1, max: 1, palette: ['blue', 'white', 'green']};
//Map.addLayer(ndvi18.clip(huc10), ndviParams, 'NDVI');

// now do it over all images
var addNDVI = function(image) {
  var ndvi = image.normalizedDifference(['B5', 'B4']).rename('NDVI')
      .clip(huc10);
  return image.addBands(ndvi);
};

// Test the addNDVI function
//var ndvi2 = addNDVI(image).select('NDVI');
//var ndviParams = {min: -1, max: 1, palette: ['blue', 'white', 'green']};
//Map.addLayer(ndvi2.clip(huc10), ndviParams, 'NDVI2');

// now map over whole L8 collection
var withNDVI = l8.map(addNDVI)
  .filterBounds(huc10);


// Create a chart with cloud mask
var cloudlessNDVI = l8.map(function(image) {
  // Get a cloud score in [0, 100].
  var cloud = ee.Algorithms.Landsat.simpleCloudScore(image).select('cloud');

  // Create a mask of cloudy pixels from an arbitrary threshold.
  var mask = cloud.lte(30);

  // Compute NDVI.
  var ndvi = image.normalizedDifference(['B5', 'B4']).rename('NDVI');

  // Return the masked image with an NDVI band.
  return image.addBands(ndvi).updateMask(mask);
});

print(ui.Chart.image.series({
  imageCollection: cloudlessNDVI.select('NDVI'),
  region: roi,
  reducer: ee.Reducer.first(),
  scale: 30
}).setOptions({title: 'Cloud-masked NDVI over time'}));

// make a greenest pixel composit across all images
var greenest = cloudlessNDVI.qualityMosaic('NDVI')
  .clip(huc10);

// Display the result.
var visParams = {bands: ['B4', 'B3', 'B2'], max: 0.3};
Map.addLayer(greenest.clip(huc10), visParams, 'Greenest pixel composite');


// Create a 3-band, 8-bit, color-IR composite to export.
//var visualization = greenest.visualize({
//  bands: ['B5', 'B4', 'B3'],
//  max: 0.4
//});


// Create a task that you can launch from the Tasks tab.
//Export.image.toDrive({
//  image: visualization,
//  description: 'Greenest_pixel_composite_klam',
//  scale: 30
//});
