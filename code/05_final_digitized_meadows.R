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
g_ndvi_s <- g_ndvi[h10_s]


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
mapview(g_ndvi_s, legend=FALSE, layer.name="Greenest Pixel", homebutton=FALSE) +
# mapview(b1[h10_s], legend=FALSE, layer.name="Band1", homebutton=FALSE) + # ndvi
# mapview(b2[h10_s], legend=FALSE, layer.name="Band2", homebutton=FALSE) + # bare
  mapview(mdws, map.types=mapbases, col.regions="seagreen2", color="seagreen", lwd=2, alpha.regions=0.1, legend=TRUE, layer.name="Meadows", homebutton=FALSE) +
  mapview(h10, map.types=mapbases, col.regions=NA, color="blue", lwd=2, alpha.regions=0.2, legend=F, homebutton=FALSE) + 
  mapview(usfs_focus, map.types=mapbases, col.regions="brown", color="brown", lwd=2, alpha.regions=0.1, legend=F)


# Make a Static Map -------------------------------------------------------

library(ggspatial)
library(USAboundaries)
library(ggthemes)
library(ggmap)
library(ggrepel)

# add diff proj
mdws_4326 <- mdws %>% st_transform(4326)
h10_4326 <- h10 %>% st_transform(4326)
h12_4326 <- h12 %>% st_transform(4326)

# get map imagery
bbxy <- c(as.numeric(st_bbox(h10_4326)))

# get imagery (try: maptype = "terrain" or source = "stamen", zoom=15,
#                     maptype = "terrain")
map_sat <- get_map(c( left = bbxy[1], bottom = bbxy[2],
                      right = bbxy[3], top = bbxy[4]), 
                   source = "google", zoom=11, 
                   maptype = "terrain")

# test
#ggmap(map_sat) + geom_sf(data=h10_4326, inherit.aes = FALSE, fill=NA, color="slateblue4")

# make state/county boundaries 
ca_bound <- USAboundaries::us_boundaries(type="state", states="ca") 
ca_cnty <- USAboundaries::us_counties(states="ca")

# select counties
ca_cnty_sel <- ca_cnty[h10_4326,]
# crop counties by h10
ca_cnty_crop <- st_intersection(ca_cnty_sel, h10_4326)

# make bbox
ca_box <- st_make_grid(h10_4326, n=1)

# plot state/county w box
(p1 <- ggplot() + 
  geom_sf(data = ca_bound, fill = NA, color = 'slategray4', size = 1, alpha = 0.4) +
  geom_sf(data=ca_cnty, 
          fill = NA, color = 'slategray4', size = 0.3, lty=2, alpha = 0.4) +
  theme(axis.text.y = element_text(angle = 90, hjust = 0.5)) +
  coord_sf() +
  theme_minimal() + 
  geom_sf(data=ca_box, color="mediumpurple4", fill=NA, lwd=1.7) +
  labs(x = NULL, y = NULL) +
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.grid.major = element_line(colour = "transparent"),
        plot.background = element_blank(),
        panel.border = element_blank(),
        plot.margin = unit(c(0, 0, 0 ,0), "mm")))


(map1 <- ggmap(map_sat) + 
    # add county boundaries
    geom_sf(data=ca_cnty_crop, inherit.aes = FALSE,
            fill = NA, color = 'slategray4', size = 0.3, lty=2, alpha = 0.4) +
    # h12 boundaries
    geom_sf(data = h12, inherit.aes = FALSE, color="slateblue2", fill=NA, size=0.5, alpha=0.8)+
    # h10 boundaries
    geom_sf(data = h10_4326, inherit.aes = FALSE,color="skyblue4", fill=NA, size=1.2, alpha=0.8)+
    # now meadows
    geom_sf(data = mdws, inherit.aes = FALSE, color = "gold3", fill="khaki1", size = 0.5, alpha=0.7) +
    # add north arrow and scale bar
    
    #annotate(geom = "text", x=-122.4, y=41.3, label="Trinity", size=3, col="gray40") +
    geom_sf_text(data=h10_4326,inherit.aes = FALSE, aes(label=NAME))+
    ggspatial::annotation_scale(location="br",text_col="black", 
                                pad_x = unit(1.2, "cm"), pad_y = unit(1, "cm"),
                                text_family = "Roboto Condensed") +
    ggspatial::annotation_north_arrow(location="tr",
                                      height = unit(1.2, "cm"), 
                                      width = unit(0.8, "cm"),
                                      pad_x = unit(1.5, "cm"),
                                      pad_y = unit(0.5, "cm"),
                                      style = north_arrow_fancy_orienteering(
                                        line_width = 1,
                                        line_col = "black",
                                        fill = c("white", "black"),
                                        text_col = "black",
                                        text_family = "Roboto Condensed",
                                        text_size = 10)) +
    theme_map(base_family = "Roboto Condensed", base_size = 15)+
    labs(x = NULL, y = NULL) +
    theme(axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          panel.grid.major = element_line(colour = "transparent"),
          plot.background = element_blank(),
          panel.border = element_blank(),
          plot.margin = unit(c(0, 0, 0 ,0), "mm")))


ggsave(filename = "figs/final_overview_map_klam_mdws.png", width = 8, height = 8.5, units = "in", dpi = 300)
ggsave(filename = "figs/final_overview_map_klam_mdws.pdf", device=cairo_pdf, width = 8, height = 11.5)
