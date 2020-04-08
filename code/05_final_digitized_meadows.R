# pull existing shapefiles in and summarize total meadows mapped


# Libraries ---------------------------------------------------------------

library(dplyr)
library(ggplot2)
library(viridis)
library(tidyr)
library(sf)
library(mapview)
library(purrr)


# Background Data ---------------------------------------------------------

# database
db <- "data/mdw_spatial_data.gpkg"

st_layers(dsn = db) 

h10 <- read_sf(dsn = db, layer="huc10_focus", quiet=TRUE) %>% 
  st_transform(4326)
h12 <- read_sf(dsn = db, layer="huc12_focus", quiet=TRUE) %>% 
  st_transform(4326)
nhd_springs <- read_sf(dsn = db, layer="nhd_springs_focus") %>% 
  st_transform(4326)
usfs_focus <- read_sf(dsn = db, layer="usfs_focus") %>% 
  st_transform(4326)
ownership_focus <- read_sf(dsn = db, layer="ownership_focus") %>% 
  st_transform(4326)
st_crs(h10)


# Read Klamath Meadows Shapefile (SERVER) ------------------------------------------
# need to be connected to VPN or on server:
mdws_path <- "/Volumes/Meadows/klamath_mapping/OUTPUT/"
st_layers(mdws_path)

# if just reading in single compilation
mdws <- read_sf(mdws_path, layer="meadows_klam_digitized_UTM", quiet = F) #%>% st_transform(4326)

# Read Klamath Meadows Shapefile (LOCAL) --------------------------------

# if just reading in single compilation
mdws <- read_sf("data/shps/meadows_klam_digitized_UTM.shp", quiet = F) 


# Read in From Geopackage -------------------------------------------------

# database
db <- "data/mdw_spatial_data.gpkg"
st_layers(db)
# read in
mdws <- read_sf(dsn = db, layer="mdws_klam_digitized", quiet=FALSE)
mdws_validate <- read_sf(dsn = db, layer="mdws_validate", quiet=FALSE)

# Evaluate ----------------------------------------------------------------

# how many?
dim(mdws)

# how much area?
st_area(mdws) %>% sum() %>% measurements::conv_unit(., from = "m2", to="hectare") # hectares

st_area(mdws) %>% sum() %>% measurements::conv_unit(., from = "m2", to="km2") # sq km 6.8

# Rename Fields -----------------------------------------------------------
# no longer necessary
# attrib_names <- c("UID_CH", "UID_INT", "BLOCK_ID", 
#                   "STREAM_YN", "TREES_YN", "TREES_G25", "ROAD_YN",
#                   "AREA_HA", "AREA_KM", "AREA_AC", "PERIMETER_M",
#                   "NWI_FID", "CONFIDENCE", "NOTES",
#                   "HUC12_ID", "HUC12_NAME", "ELEV_MEAN_M", "ELEV_RANGE_M",
#                   "EDGE_COMPLEXITY", "CENTROID_X", "CENTROID_Y", "geometry"
#                   )
# 
# mdws <- set_names(mdws, attrib_names)
  
  # Get Greenest Pixel Data -------------------------------------------------

# read in a raster/tif
library(stars)
g_ndvi <- read_stars("data/Greenest_pixel_composite_klamath.tif") 
elev <- read_stars("data/rasters/klam_10m_DEM.tif") 

# check dims and crs
stars::st_dimensions(g_ndvi)
st_crs(g_ndvi) <- 4326
st_crs(g_ndvi)

# clip to data (huc10)
h10_s <- h10 %>% filter(HUC10=="1801021102")

# pull out single bands
b1 <- g_ndvi[,,,1] # a single band
b2 <- g_ndvi[,,,2] # a single band
b3 <- g_ndvi[,,,3] # a single band

# crop raster to specific area (h10 south in this case)
b1_s <- b1[h10_s]

# crop layer for simpler plot
ndvi_s <- g_ndvi[h10_s]

# plot
# ggplot() + 
#   #geom_stars(data = b1_s) + # equivalent w below
#   geom_stars(data = ndvi_s[,,,1]) + # equivalent w above
#   #facet_wrap(~band) +
#   coord_equal() +
#   theme_void() +
#   viridis::scale_fill_viridis("Greenest Pixel", na.value="transparent")

# Map ---------------------------------------------------------------------

# make a mapview map
# maptypes to use:
mapbases <- c("Stamen.TonerLite","OpenTopoMap", "CartoDB.PositronNoLabels", "OpenStreetMap",
              "Esri.WorldImagery", "Esri.WorldTopoMap","Esri.WorldGrayCanvas"
)


# mdw map
mapview(b1[h10_s], legend=FALSE, layer.name="Band1", homebutton=FALSE) + # ndvi
mapview(b2[h10_s], legend=FALSE, layer.name="Band2", homebutton=FALSE) + # bare
  mapview(mdws, map.types=mapbases, col.regions="seagreen2", color="seagreen", lwd=2, alpha.regions=0.1, legend=TRUE, layer.name="Meadows", homebutton=FALSE) +
  mapview(h10, map.types=mapbases, col.regions=NA, color="blue", lwd=2, alpha.regions=0.2, legend=F, homebutton=FALSE) + 
  mapview(usfs_focus, map.types=mapbases, col.regions="brown", color="brown", lwd=2, alpha.regions=0.1, legend=F)
