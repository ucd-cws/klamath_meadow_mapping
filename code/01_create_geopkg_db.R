## CREATE GEOSPATIAL DATABASE

# Read in Spatial Data and save out to Geopackage

library(tidyverse)
library(RSQLite)
library(sf)
library(mapview)

# projections
## CRS NAD83 3310
## CRS WGS84 4326
## CRS GRS80 4269

# Data From ---------------------------------------------------------------

# Data from Gabrielle: 

# Meadow Mapping Data: https://drive.google.com/drive/u/1/folders/0ADCofmEiv8TXUk9PVA
  ## includes: CNPS meadow photos, the Fen_Meadow_Shasta_Trinity DB, and associated docs

# Shapefiles (Focus Area Layers-20190909T192321Z-001)
  ## includes: H10/12 Watersheds, FS Lands, BasicOwnership

# Read in Shapes ----------------------------------------------------------

# huc12
h12_focus <- st_read("data/shps/HUC12Watersheds_FocusArea.shp") %>% 
  st_transform(3310)
st_crs(h12_focus)
#mapview(h12_focus)

# huc10
h10_focus <- st_read("data/shps/HUC10Watersheds_FocusArea.shp") %>% 
  st_transform(3310)
st_crs(h10_focus)
#mapview(h10_focus)

# springs
springs <- st_read("data/shps/NHDPlus_spring_seeps.shp") %>% st_transform(3310)
# crop to just the focus area:
springs_focus <- st_intersection(springs, h10_focus) %>% select(-c(OBJECTID:STATES, HUTYPE:SHAPE_LEN))

# ownership
ownership_focus <- st_read("data/shps/BasicOwnership_FocusArea.shp") %>% st_transform(3310)

# FS lands
usfs_focus <- st_read("data/shps/FSLands_FocusArea.shp") %>% st_transform(3310)
st_crs(usfs_focus)


# Write to Geopackage -----------------------------------------------------

# write to geopackage
st_write(h12_focus, dsn = 'data/mdw_spatial_data.gpkg', layer = 'huc12_focus')
st_write(h10_focus, dsn = 'data/mdw_spatial_data.gpkg', layer = 'huc10_focus')
st_write(springs_focus, dsn="data/mdw_spatial_data.gpkg", layer = "nhd_springs_focus")
st_write(ownership_focus, dsn="data/mdw_spatial_data.gpkg", layer = "ownership_focus")
st_write(usfs_focus, dsn="data/mdw_spatial_data.gpkg", layer = "usfs_focus", delete_layer = T, update = T)

# Check Layers ------------------------------------------------------------

st_layers(dsn = 'data/mdw_spatial_data.gpkg') # gives all spatial layers and dims 

# Read in a Spatial File from DB ------------------------------------------

h10 <- st_read(dsn = 'data/mdw_spatial_data.gpkg', layer="huc10_focus")
h12 <- st_read(dsn = 'data/mdw_spatial_data.gpkg', layer="huc12_focus")
nhd_springs <- st_read(dsn = 'data/mdw_spatial_data.gpkg', layer="nhd_springs_focus")
usfs_focus <- st_read(dsn = 'data/mdw_spatial_data.gpkg', layer="usfs_focus")
ownership_focus <- st_read(dsn = 'data/mdw_spatial_data.gpkg', layer="ownership_focus")


# Map ---------------------------------------------------------------------

# make a mapview map
# maptypes to use:
mapbases <- c("Stamen.TonerLite","OpenTopoMap", "CartoDB.PositronNoLabels", "OpenStreetMap", 
              "Stamen.Terrain", "Stamen.TopOSMRelief", "Stamen.TopOSMFeatures",
              "Esri.WorldImagery", "Esri.WorldTopoMap","Esri.WorldGrayCanvas"
)

mapview(h10, map.types=mapbases, col.regions=NA, color="blue", lwd=2, alpha.regions=0.2, legend=F) + 
  mapview(h12, map.types=mapbases, col.regions=NA, color="skyblue", lwd=1, alpha.regions=0.2, legend=F) +
  mapview(usfs_focus, map.types=mapbases, col.regions=NA, color="brown", lwd=2, alpha.regions=0.2, legend=F) + 
  mapview(ownership_focus, map.types=mapbases, zcol="OWNERCLASS",  lwd=.7, alpha.regions=0.2, layer.name="Land Owner")

# Add/Read in Table -----------------------------------------------------------

# connect to database using dplyr
dbcon <- src_sqlite("data/mdw_spatial_data.gpkg", create = F) 

# check list of table names
src_tbls(dbcon)

# check size of tables
map(src_tbls(dbcon), ~dim(dbReadTable(dbcon$con, .))) %>% 
  set_names(., src_tbls(dbcon))

# quickly see dim of single tables
dim(dbReadTable(dbcon$con, "huc10_focus"))


# ADD A TABLE
# works but can't overwrite without append=TRUE, overwrite=T
#copy_to(dbcon, mytable, temporary = FALSE, overwrite=TRUE) 

# get table data
#mytable <- tbl(dbcon, "mytable") %>%  collect


