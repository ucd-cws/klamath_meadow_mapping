# pull existing shapefiles in and summarize total meadows mapped


# Libraries ---------------------------------------------------------------

library(tidyverse)
library(viridis)
library(sf)
library(mapview)
library(purrr)

# proj to use
proj_sel <- 6339

# Background Data ---------------------------------------------------------

# database
db <- "data/mdw_spatial_data.gpkg"

# get layers
st_layers(dsn = db) 

h10 <- read_sf(dsn = db, layer="huc10_focus", quiet=TRUE) %>% 
  st_transform(proj_sel)
h12 <- read_sf(dsn = db, layer="huc12_focus", quiet=TRUE) %>% 
  st_transform(proj_sel)
nwi_focus <- read_sf(dsn = db, layer="nwi_focus_area") %>% 
  st_transform(proj_sel)
nhd_springs <- read_sf(dsn = db, layer="nhd_springs_focus") %>% 
  st_transform(proj_sel)
usfs_focus <- read_sf(dsn = db, layer="usfs_focus") %>% 
  st_transform(proj_sel)
ownership_focus <- read_sf(dsn = db, layer="ownership_focus") %>% 
  st_transform(proj_sel)

# if just reading in single compilation
mdws <- read_sf(dsn=db, layer="mdws_klam_digitized") %>% st_transform(proj_sel)

mdws_validate <- read_sf(dsn=db, layer="mdws_validate") %>% st_transform(proj_sel)

# GETTING RAW SHPS: Read and Combine Mapped Mdw Shapefiles -------------------------

# # need to be connected to VPN or on server:
# mdws_path <- "/Volumes/Meadows/klamath_mapping/GIS/layers/Meadow_Shapefiles/"
# 
# # get all named meadow blocks
# mdw_shps <- list.files(mdws_path, pattern="^Meadows_[0-9]{3}\\.shp$")
# 
# # read in each shape file, merge them and make into sf features
# mdws <- tibble(fname = mdw_shps) %>%
#   mutate(data = map(paste0(mdws_path, fname), read_sf)) %>%
#   unnest(data) %>%
#   st_as_sf() %>%
#   st_set_crs(4269)

# Add Attributes ----------------------------------------------------------

# Add area/perimeter attributes to shapefile
mdws$area_ha <- st_area(mdws) %>% measurements::conv_unit(., from = "m2", to="hectare") # hectares
mdws$area_km2 <- st_area(mdws) %>% measurements::conv_unit(., from = "m2", to="km2") # sq km
mdws$area_acre <- st_area(mdws) %>% measurements::conv_unit(., from = "m2", to="acre") # sq km
mdws$perimeter_m <- round(as.numeric(st_perimeter(mdws)),3)
mdws$area_ha <- round(as.numeric(mdws$area_ha),2)
mdws$area_km2 <- round(as.numeric(mdws$area_km2),3)
mdws$area_acre <- round(as.numeric(mdws$area_acre),2)

# Standardize text attributes
mdws$Confidence[grepl("igh", mdws$Confidence, ignore.case = T)] <- "High"
mdws$Confidence[grepl("^M", mdws$Confidence, ignore.case = T)] <- "Moderate"

# Add unique identifiers
set.seed(99)
mdws$UID_ch <- proquint(length(mdws$Block_ID), n_words = 1)
mdws$UID_int <- proquint_to_int(mdws$UID_ch)

# Add HUC12 attributes
mdws <- st_join(mdws, st_transform(h12[,c("HUC12", "NAME")], st_crs(mdws)), left = T, largest = T)

# Add centroid coordinates
mdws$centroid_x <- st_coordinates(st_centroid(st_geometry(mdws)))[,1]
mdws$centroid_y <- st_coordinates(st_centroid(st_geometry(mdws)))[,2]

# Calculate average elevation for each meadow
#mdws$Elev_mean <- geobgu::raster_extract(elev, mdws, fun = mean, na.rm = TRUE)

elev_stats <- data.frame(emean = extract(elev, as(mdws, "Spatial"), fun=mean, na.rm = T), 
                         emin = extract(elev, as(mdws, "Spatial"), fun=min, na.rm = T),
                         emax = extract(elev, as(mdws, "Spatial"), fun=max, na.rm = T))
mdws$Elev_mean <- round(elev_stats$emean,3)
mdws$Elev_range <- round(elev_stats$emax - elev_stats$emin, 3)

# generate edge complexity:
# ratio of the shoreline length (i.e. perimeter in km) to the 
# perimeter of an equally sized circle
mdws <- mdws %>% 
  mutate(edge_complex = ((PERIMET/1000) / (2*sqrt(pi*AREA_KM))))
# gives edge_complexity in km

# standardize names
names(mdws) <- toupper(names(mdws))

# make a list of attributes
attrib_names <- c("UID_CH", "UID_INT", "BLOCK_ID", 
                  "STREAM_YN", "TREES_YN", "TREES_G25", "ROAD_YN",
                  "AREA_HA", "AREA_KM", "AREA_AC", "PERIMETER_M",
                  "NWI_FID", "CONFIDENCE", "NOTES",
                  "HUC12_ID", "HUC12_NAME", 
                  "ELEV_MEAN_M", "ELEV_RANGE_M",
                  "EDGE_COMPLEXITY", 
                  "CENTROID_X", "CENTROID_Y", "geometry")

# organize cols
# mdws <- mdws[,c("UID_ch", "UID_int", "Block_ID", "Stream_YN", 
#                 "Trees_YN", "Trees_g25", 
#                 "Road_YN", "area_ha", "area_km2", "area_acre", 
#                 "perimeter_m", "NWI_FID", "Confidence", 
#                 "Notes", "HUC12", "NAME", "Elev_mean", "Elev_range", 
#                 "edge_complexity", "centroid_x", "centroid_y", "geometry")] 

mdws <- set_names(mdws, attrib_names)

# Summarize Meadows -------------------------------------------------------

# how many?
# dim(mdws)
# 
# # how much area? (hectares)
# st_area(mdws) %>% sum() %>% measurements::conv_unit(., from = "m2", to="hectare") 
# 
# # area in sq km (6.8)
# st_area(mdws) %>% sum() %>% measurements::conv_unit(., from = "m2", to="km2") 

# save this out:
# update <- gsub(pattern = "-", replacement = "_", x = Sys.Date())
# st_write(mdws, dsn = db,
#          layer = glue::glue('meadows_klam_digitized_{update}'),
#          delete_layer = TRUE) # add delete true to allow overwrite

# double check:
# st_layers(db)

# Get Greenest Pixel Data -------------------------------------------------

# read in a raster/tif
library(raster)
library(stars)

g_ndvi <- read_stars("data/Greenest_pixel_composite_klamath.tif") 

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

#par(mfrow = c(1, 3))
plot(g_ndvi, 
     interpolate = TRUE, reset = FALSE,
     col = viridis::viridis(24), 
     main="Greenest Pixel (ndvi)")

# plot rgb
plot(g_ndvi[h10_s],
     rgb=1:3,
     interpolate = TRUE, reset = FALSE,
     main="Greenest Pixel (ndvi)")


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
#mapview(b1[h10_s], legend=FALSE, layer.name="Band1", homebutton=FALSE) + # ndvi
#mapview(b2[h10_s], legend=FALSE, layer.name="Band2", homebutton=FALSE) + # bare
  mapview(mdws, map.types=mapbases, col.regions="seagreen2", color="seagreen", lwd=2, alpha.regions=0.1, legend=TRUE, layer.name="Meadows", homebutton=FALSE) +
  mapview(h10, map.types=mapbases, col.regions=NA, color="blue", lwd=2, alpha.regions=0.2, legend=F, homebutton=FALSE) + 
  mapview(usfs_focus, map.types=mapbases, col.regions="brown", color="brown", lwd=2, alpha.regions=0.1, legend=F)

