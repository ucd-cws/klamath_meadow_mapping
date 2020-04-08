# READ GEOPACKAGE

# Libraries ---------------------------------------------------------------

library(tidyverse)
library(RSQLite)
library(sf)
# devtools::install_github("r-spatial/mapview@develop")
# if using sf version 9.0 or above, need to install mapview dev version
library(mapview)

# Read in a Spatial File from DB ------------------------------------------

# database
db <- "data/mdw_spatial_data.gpkg"

# check layers
st_layers(db) 

h10 <- read_sf(dsn = db, layer="huc10_focus", quiet=FALSE)
h12 <- read_sf(dsn = db, layer="huc12_focus", quiet=TRUE) # use default quiet
nwi <- read_sf(dsn = db, layer="nwi_focus_area")
nhd_springs <- read_sf(dsn = db, layer="nhd_springs_focus")
usfs_focus <- read_sf(dsn = db, layer="usfs_focus")
ownership_focus <- read_sf(dsn = db, layer="ownership_focus")

# now digitized meadows
mdws <- read_sf(dsn=db, layer="mdws_klam_digitized")

# check
st_crs(mdws)

# Mapview Map ---------------------------------------------------------------------

# maptypes to use:
mapbases <- c("Stamen.TonerLite","OpenTopoMap", "CartoDB.PositronNoLabels", "OpenStreetMap", 
              "Stamen.Terrain", "Stamen.TopOSMRelief", "Stamen.TopOSMFeatures",
              "Esri.WorldImagery", "Esri.WorldTopoMap","Esri.WorldGrayCanvas"
)

mapview(h10, map.types=mapbases, col.regions=NA, color="blue", lwd=2, alpha.regions=0.2, legend=F) + 
  mapview(h12, map.types=mapbases, col.regions=NA, color="skyblue", lwd=1, alpha.regions=0.2, legend=F) +
  mapview(nwi, map.types=mapbases, col.regions="darkgreen", color="green",layer.name="NWI Wetlands")+
  mapview(usfs_focus, map.types=mapbases, col.regions=NA, color="brown", lwd=2, alpha.regions=0.2, legend=F) + 
  mapview(ownership_focus, map.types=mapbases, zcol="OWNERCLASS",  lwd=.7, alpha.regions=0.2, layer.name="Land Owner")

