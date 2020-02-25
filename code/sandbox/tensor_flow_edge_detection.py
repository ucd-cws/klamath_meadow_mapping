# Python Code for Tensor Flow Edge Detection with 3 bands
# https://developers.google.com/earth-engine/tf_examples


# Use these bands for prediction.
bands = ['B2', 'B3', 'B4', 'B5', 'B6', 'B7']
# Use Landsat 8 surface reflectance data.
l8sr = ee.ImageCollection('LANDSAT/LC08/C01/T1_SR')

# Cloud masking function.
def maskL8sr(image):
  cloudShadowBitMask = ee.Number(2).pow(3).int()
cloudsBitMask = ee.Number(2).pow(5).int()
qa = image.select('pixel_qa')
mask = qa.bitwiseAnd(cloudShadowBitMask).eq(0).And(
  qa.bitwiseAnd(cloudsBitMask).eq(0))
return image.updateMask(mask).select(bands).divide(10000)

# The image input data is a 2018 cloud-masked median composite.
image = l8sr.filterDate('2018-01-01', '2018-12-31').map(maskL8sr).median()

# Use folium to visualize the imagery.
mapIdDict = image.getMapId({'bands': ['B4', 'B3', 'B2'], 'min': 0, 'max': 0.3})
map = folium.Map(location=[38., -122.5])
folium.TileLayer(
  tiles=mapIdDict['tile_fetcher'].url_format,
  attr='Map Data &copy; <a href="https://earthengine.google.com/">Google Earth Engine</a>',
  overlay=True,
  name='median composite',
).add_to(map)
map.add_child(folium.LayerControl())
map