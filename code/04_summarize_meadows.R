# pull existing shapefiles in and summarize total meadows mapped


# Libraries ---------------------------------------------------------------

library(tidyverse)
library(RSQLite)
library(sf)
library(mapview)
library(mapedit)
library(purrr)


# Background Data ---------------------------------------------------------

# database
db <- "data/mdw_spatial_data.gpkg"

st_layers(dsn = db) 

h10 <- read_sf(dsn = db, layer="huc10_focus", quiet=TRUE)
h12 <- read_sf(dsn = db, layer="huc12_focus", quiet=TRUE) 
nhd_springs <- read_sf(dsn = db, layer="nhd_springs_focus")
usfs_focus <- read_sf(dsn = db, layer="usfs_focus")
ownership_focus <- read_sf(dsn = db, layer="ownership_focus")


# Read in Meadow Shapes ----------------------------------------------------

# need to be connected to VPN or on server:
mdws_path <- "/Volumes/Meadows/klamath_mapping/GIS/layers/Meadow_Shapefiles/"

# get all named meadow blocks
mdw_shps <- list.files(mdws_path, pattern="^Meadows_[0-9]{3}\\.shp$")

# check one
# read_sf(paste0(mdws_path, mdw_shps[1]), quiet = FALSE)


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

# Map ---------------------------------------------------------------------

# make a mapview map
# maptypes to use:
mapbases <- c("Stamen.TonerLite","OpenTopoMap", "CartoDB.PositronNoLabels", "OpenStreetMap",
              "Esri.WorldImagery", "Esri.WorldTopoMap","Esri.WorldGrayCanvas"
)


# mdw map
mapview(mdws, map.types=mapbases, col.regions="seagreen2", color="seagreen", lwd=2, alpha.regions=0.1, legend=TRUE, layer.name="Meadows") +
  mapview(h10, map.types=mapbases, col.regions=NA, color="blue", lwd=2, alpha.regions=0.2, legend=F) + 
  mapview(usfs_focus, map.types=mapbases, col.regions="brown", color="brown", lwd=2, alpha.regions=0.1, legend=F)


# other stuff map
mapview(h10, map.types=mapbases, col.regions=NA, color="blue", lwd=2, alpha.regions=0.2, legend=F) + 
  mapview(h12, map.types=mapbases, col.regions=NA, color="skyblue", lwd=1, alpha.regions=0.2, legend=F) +
  mapview(usfs_focus, map.types=mapbases, col.regions=NA, color="brown", lwd=2, alpha.regions=0.2, legend=F) + 
  mapview(ownership_focus, map.types=mapbases, zcol="OWNERCLASS",  lwd=.7, alpha.regions=0.2, layer.name="Land Owner")

