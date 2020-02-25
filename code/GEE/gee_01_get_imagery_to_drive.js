var huc10 = ee.FeatureCollection("users/rapeek/HUC10Watersheds_FocusArea"),
    roi = /* color: #d63000 */ee.Geometry.Point([-122.72278395403117, 41.32239158947847]);
    

// import NAIP imagery
var naipIMGs = ee.ImageCollection('USDA/NAIP/DOQQ') 
            .filter(ee.Filter.date('2011-01-01', '2016-12-31'))
            .filterBounds(huc10);

var cropH10 = function(image) {
  return image.clip(huc10); 
};

// map over the images and crop
var naipcrop = naipIMGs.map(cropH10);

// get the least cloudy image in 2018
var naipImage = ee.Image(
    naipcrop.filterBounds(huc10)
    .sort('CLOUD_COVER')
    .first()
);

// select bands (RBG, not near infrared)
var naipColor = naipcrop.select(['R', 'G', 'B']);
var naipImage = naipImage.select(['R','G','B'])

var naipColorVis = {
  min: 0.0,
  max: 255.0,
};

// Now map
Map.centerObject(huc10);
Map.addLayer(naipColor, naipColorVis, 'NAIP');
Map.addLayer(huc10, {},'H10');
Map.addLayer(naipImage, naipColorVis, 'naip_cloudless');

// Get LSAT8
var l8 = ee.ImageCollection('LANDSAT/LC08/C01/T1_TOA')
  .filterBounds(huc10);

// map over the images and crop
var l8crop = l8.map(cropH10)

// get the least cloudy image
var imagel8 = ee.Image(
    l8crop.filterBounds(huc10)
    //.filterDate('2000-05-01', '2018-10-31')
    .sort('CLOUD_COVER')
    .first()
);


// Display the result
//Map.addLayer(imagel8, 'LSAT least cloud');


// Create a task that you can launch from the Tasks tab.
//Export.image.toDrive({
//  image: visualization,
//  description: 'LSAT_least_cloudy_klam',
//  scale: 30
//});
