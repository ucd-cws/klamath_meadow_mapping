var collection = ee.ImageCollection("LANDSAT/LC08/C01/T1_TOA"),
    roi = /* color: #d63000 */ee.Geometry.Polygon(
        [[[-113.0712890625, 40.64730350141041],
          [-111.95068359375, 40.6389672826975],
          [-111.95068359375, 41.71393001324647],
          [-113.09326171875, 41.722130525008644]]]),
    collection84 = ee.ImageCollection("LANDSAT/LT05/C01/T1_TOA");


collection = collection.filterBounds(roi)
        .filterDate('2017-01-01', '2017-12-31')
print(collection.size())

var maskClouds = function(image){
  var scored = ee.Algorithms.Landsat.simpleCloudScore(image);
  var mask = scored.select(['cloud']).lte(50);
  return image.updateMask(mask)
};
var filterCollection = collection.map(maskClouds);
var image = ee.Image(filterCollection.first());
//Map.addLayer(image, {bands:['B5','B4','B3']}, 'no-cloud')

//var image1 = ee.Image(collection.first());
//Map.addLayer(image1, {bands:['B5','B4','B3']}, 'cloud')

var median = filterCollection.median();
print(median);

Map.addLayer(median, {bands:['B5','B4','B3'], min: 0, max: 0.5,},
'composite')


var ndwi = median.normalizedDifference(['B3','B5']);
Map.addLayer(ndwi, {palette: ['00FFFF', '0000FF']}, 'ndwi17')

var water17 = ndwi.gte(0.3);
Map.addLayer(water17, {}, 'mask17')


var image84 = collection84
              .filterDate('1990-01-01','1990-12-31')
              .filterBounds(roi)
              .map(maskClouds)
              .median();

var water84 = image84.normalizedDifference(['B2','B4'])
                    .gte(0.3);

var change = water84.neq(water17);
change = change.updateMask(change)
Map.addLayer(change,{palette:'FF0000'},'change');

var areaImage = change.multiply(ee.Image.pixelArea());

var stats = areaImage.reduceRegion({
  reducer: ee.Reducer.sum(),
  geometry: roi,
  scale: 100,
  maxPixels: 1e9
});
print('loss area: ', stats, 'sq m');
