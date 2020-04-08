// LEAST CLOUDY ----------------------------------------------
var huc10 = ee.FeatureCollection("users/ldnagel-ucd/HUC10Watersheds_FocusArea"),
    roi = /* color: #d63000 */ee.Geometry.Point([-122.72278395403117, 41.32239158947847]);
	
// import Sentinel imagery
var sent07 = ee.ImageCollection('COPERNICUS/S2_SR') 
            .filter(ee.Filter.date('2019-07-01', '2019-07-31'))
            .filterBounds(huc10);
			
// make function to crop by huc10
var cropH10 = function(image) {
  return image.clip(huc10); 
};

// map over the images and crop
var sent07_c = sent07.map(cropH10);// get the least cloudy image in July
var sent07_cc = ee.Image(
    sent07_c.filterBounds(huc10)
    .sort('CLOUD_COVER')
    .first()
);

// select Visible RGB bands (see here: https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S2_SR)
var sent07_cc_vis = sent07_cc.select(['TCI_R', 'TCI_G', 'TCI_B']);

// Now map
Map.centerObject(huc10);
Map.addLayer(huc10, {},'H10');

//Map.addLayer(sent07_cc, VPsent07_cc, 'Less-Cloud-Sent');
Map.addLayer(sent07_cc_vis, {}, 'S2-cloudless');

// Create a task that you can launch from the Tasks tab.
Export.image.toDrive({  
  image: sent07_cc_vis,
  description: 'klam_sent2_img_201907',
  scale: 10,
  region: huc10,
  maxPixels: 1e10,
  fileFormat: 'GeoTIFF',
  formatOptions: {
    cloudOptimized: true
  }
});





// CLOUD COMPOSITE --------------------------------------------------------------------------

var huc10 = ee.FeatureCollection("users/ldnagel-ucd/HUC10Watersheds_FocusArea"),
    roi = /* color: #d63000 */ee.Geometry.Point([-122.72278395403117, 41.32239158947847]);


// import Sentinel imagery
var sent10 = ee.ImageCollection('COPERNICUS/S2_SR') 
            .filter(ee.Filter.date('2019-10-01', '2019-10-30'))
            .filterBounds(huc10);

var cropH10 = function(image) {
  return image.clip(huc10); 
};

// map over the images and crop
var sent10_c = sent10.map(cropH10);

//cloud reduction 
var maskClouds = function(image) {
  var scored =  ee.Algorithms.Landsat.simpleCloudScore(image);
  return image.updateMask(scored.select(['cloud']).lt(50));
};

// get the least cloudy image in 2018
//var sent06_cc = ee.Image(
//    sent06_c.filterBounds(huc10)
//    .sort('CLOUD_COVER')
//    .first()
//);

//add the L8 image collection to your map below to visualize it
var VPsent10_c = {bands: ['B4', 'B3', 'B2'], min: 0, max:5000};
Map.addLayer(sent10_c, VPsent10_c, 'Less-Cloud-Sent');




//var visualization = sentcrop.visualize({
//  bands: ['B5', 'B4', 'B3'],
//  max: 0.4
//});

// Create a task that you can launch from the Tasks tab.
Export.image.toDrive({
  image: sent10_c,
  description: 'Sentinel_Img_201910_cfilter',
  scale: 10
});

