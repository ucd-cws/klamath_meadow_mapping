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

# if just reading
# read in
mdws <- read_sf(db, layer="meadows_klam_digitized_2020_03_03") %>% 
  st_transform(4326)

# Read and Combine Meadow Digitization Shapefiles -------------------------

# need to be connected to VPN or on server:
mdws_path <- "/Volumes/Meadows/klamath_mapping/GIS/layers/Meadow_Shapefiles/"

# get all named meadow blocks
mdw_shps <- list.files(mdws_path, pattern="^Meadows_[0-9]{3}\\.shp$")

# check one
# read_sf(paste0(mdws_path, mdw_shps[1]), quiet = FALSE)

# read in each shape file, merge them and make into sf features
mdws <- tibble(fname = mdw_shps) %>%
  mutate(data = map(paste0(mdws_path, fname), read_sf)) %>%
  unnest(data) %>%
  st_as_sf() %>%
  st_set_crs(4269)

# how many?
dim(mdws)

# how much area?
st_area(mdws) %>% sum() %>% measurements::conv_unit(., from = "m2", to="hectare") # hectares

st_area(mdws) %>% sum() %>% measurements::conv_unit(., from = "m2", to="km2") # sq km

# save this out:
update <- gsub(pattern = "-", replacement = "_", x = Sys.Date())
st_write(mdws, dsn = db,
         layer = glue::glue('meadows_klam_digitized_{update}'),
         delete_layer = TRUE) # add delete true to allow overwrite

# double check:
st_layers(db)

# Get Greenest Pixel Data -------------------------------------------------

# read in a raster/tif
library(stars)
g_ndvi <- read_stars("data/Greenest_pixel_composite_klamath.tif") 

# check dims and crs
stars::st_dimensions(g_ndvi)
st_crs(g_ndvi)

# clip to data (huc10)
h10_s <- h10 %>% filter(HUC10=="1801021102")

# pull out single bands
b1 <- g_ndvi[,,,1] # a single band
b2 <- g_ndvi[,,,2] # a single band
b3 <- g_ndvi[,,,3] # a single band

# crop raster to specific area (h10 south in this case)
b1_s <- b1[h10_s]

#par(mfrow = c(1, 3))
plot(b1_s, 
     interpolate = TRUE, reset = FALSE,
     col = viridis::viridis(24), 
     main="Greenest Pixel (ndvi)")

# plot rgb
# plot(g_ndvi[h10_s], 
#      rgb=1:3, 
#      interpolate = TRUE, reset = FALSE,
#      main="Greenest Pixel (ndvi)")


# TEST MAPVIEW: try with legend=FALSE or it breaks
mapview(b1[h10_s], legend=FALSE, layer.name="Band1") + # ndvi
  mapview(b2[h10_s], legend=FALSE, layer.name="Band2") + # bare ground
  mapview(mdws, col.regions="seagreen2", color="seagreen", lwd=2, alpha.regions=0.1, legend=TRUE, layer.name="Meadows") 

# make a GGPLOT

# crop layer for simpler plot
ndvi_s <- g_ndvi[h10_s]

# plot
ggplot() + 
  #geom_stars(data = b1_s) + # equivalent w below
  geom_stars(data = ndvi_s[,,,1]) + # equivalent w above
  #facet_wrap(~band) +
  coord_equal() +
  theme_void() +
  viridis::scale_fill_viridis("Greenest Pixel", na.value="transparent")


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

