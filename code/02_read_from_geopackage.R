# READ GEOPACKAGE

# Libraries ---------------------------------------------------------------

library(tidyverse)
library(RSQLite)
library(sf)
library(mapview)

# Read in a Spatial File from DB ------------------------------------------

# database
db <- "data/mdw_spatial_data.gpkg"

h10 <- read_sf(dsn = db, layer="huc10_focus", quiet=FALSE)
h12 <- read_sf(dsn = db, layer="huc12_focus", quiet=TRUE) # use default quiet
nhd_springs <- read_sf(dsn = db, layer="nhd_springs_focus")
usfs_focus <- read_sf(dsn = db, layer="usfs_focus")
ownership_focus <- read_sf(dsn = db, layer="ownership_focus")


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
