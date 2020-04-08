## CREATE GEOSPATIAL DATABASE OF MDWS DATA

# Read in Spatial Data and save out to Geopackage

library(tidyverse)
library(RSQLite)
library(sf)
library(mapview)

# projections
## CRS NAD83 6339 UTM Zone 10N NAD83 2011
## CRS NAD83 3310 CA Teal Albers
## CRS WGS84 4326
## CRS GRS80 4269

# Data From ---------------------------------------------------------------

# Data from Gabrielle: 

# Meadow Mapping Data: https://drive.google.com/drive/u/1/folders/0ADCofmEiv8TXUk9PVA
  ## includes: CNPS meadow photos, the Fen_Meadow_Shasta_Trinity DB, and associated docs

# Shapefiles (Focus Area Layers-20190909T192321Z-001)
  ## includes: H10/12 Watersheds, FS Lands, BasicOwnership

# Read in Shapes ----------------------------------------------------------

# set proj of interest
proj_sel <- 6339

# huc12
h12_focus <- read_sf("data/shps/HUC12Watersheds_FocusArea.shp", quiet = F) %>% 
  st_transform(proj_sel)
st_crs(h12_focus)

# huc10
h10_focus <- read_sf("data/shps/HUC10Watersheds_FocusArea.shp") %>% 
  st_transform(proj_sel)

# NWI Focus Area
nwi <- read_sf("data/shps/NWI_Focus_Area.shp") %>%
  st_transform(proj_sel)

# springs
springs <- read_sf("data/shps/NHDPlus_spring_seeps.shp") %>%
  st_transform(proj_sel)

# crop to just the focus area:
springs_focus <- st_intersection(springs, h10_focus) %>% select(-c(OBJECTID:STATES, HUTYPE:SHAPE_LEN))

# ownership
ownership_focus <- st_read("data/shps/BasicOwnership_FocusArea.shp") %>% 
  st_transform(proj_sel)

# FS lands
usfs_focus <- read_sf("data/shps/FSLands_FocusArea.shp") %>% 
  st_transform(proj_sel)
st_crs(usfs_focus)

# meadows layer
mdws <- read_sf("data/shps/meadows_klam_digitized_UTM.shp", quiet = F) %>% 
  st_transform(proj_sel)

# fix attrib names:
attrib_names <- c("UID_CH", "UID_INT", "BLOCK_ID", 
                  "STREAM_YN", "TREES_YN", "TREES_G25", "ROAD_YN",
                  "AREA_HA", "AREA_KM", "AREA_AC", "PERIMETER_M",
                  "NWI_FID", "CONFIDENCE", "NOTES",
                  "HUC12_ID", "HUC12_NAME", 
                  "ELEV_MEAN_M", "ELEV_RANGE_M",
                  "EDGE_COMPLEXITY", 
                  "CENTROID_X", "CENTROID_Y", "geometry")

mdws <- set_names(mdws, attrib_names)


# meadows to groundtruth/validate
mdws_validate <- read_sf("data/shps/Meadows_Validate.shp", quiet = F) %>% 
  st_transform(proj_sel)

st_crs(mdws_validate)

# Write to Geopackage -----------------------------------------------------

# write to geopackage
st_write(h12_focus, dsn = 'data/mdw_spatial_data.gpkg', 
         layer = 'huc12_focus', 
         # delete entire geopackage first if it exists?
         delete_dsn = TRUE, 
         # allow overwrite of the layer in the gpkg 
         delete_layer = TRUE) 

# for remaining layers, don't need the `delete_dsn` option
st_write(h10_focus, dsn = 'data/mdw_spatial_data.gpkg', 
         layer = 'huc10_focus', delete_layer = TRUE)
st_write(nwi, dsn="data/mdw_spatial_data.gpkg", 
         layer = "nwi_focus_area", delete_layer = TRUE)
st_write(springs_focus, dsn="data/mdw_spatial_data.gpkg", 
         layer = "nhd_springs_focus", delete_layer = TRUE)
st_write(ownership_focus, dsn="data/mdw_spatial_data.gpkg",
         layer = "ownership_focus", delete_layer = TRUE)
st_write(usfs_focus, dsn="data/mdw_spatial_data.gpkg",
         layer = "usfs_focus", delete_layer = TRUE)
st_write(mdws, dsn = 'data/mdw_spatial_data.gpkg', 
         layer = 'mdws_klam_digitized', delete_layer = TRUE)
st_write(mdws_validate, dsn = 'data/mdw_spatial_data.gpkg', 
         layer = 'mdws_validate', delete_layer = TRUE)

# Check Layers ------------------------------------------------------------

st_layers(dsn = 'data/mdw_spatial_data.gpkg') 
# gives all spatial layers and dims, should see all we added above
