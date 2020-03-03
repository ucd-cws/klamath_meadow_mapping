# map elevation by streamline

library(nhdplusTools)
library(sf)
library(tidyverse)
library(elevatr) # https://cran.r-project.org/web/packages/elevatr/vignettes/introduction_to_elevatr.html
library(mapview)

# First Get Salmon River --------------------------------------------------

sr_mouth <- c("lon"=-123.492893, "lat"=41.378075)
sr_forks <- c("lon"=-123.323399, "lat"=41.256802)
sr_upper_sf<- c("lon"=-123.016133, "lat"=41.076408)

# bind together
salmon <- bind_rows(sr_mouth, sr_forks, sr_upper_sf)

# make spatial
salmon_pts <- tibble("site"=c("sr_mouth","sr_forks","sr_upper_sf"), 
                     "lon"=salmon$lon, "lat"=salmon$lat, "dist_zero"=c(0,31.1, 77.5)) %>% 
  st_as_sf(., coords=c("lon","lat"), crs=4326, remove=FALSE)

# get the flowline for these points
flowlines_raw <-get_flowlines(1, salmon_pts)

# filter to salmon
flowlines_salmon <- filter(flowlines_raw, grepl("^Salmon River$|^South Fork Salmon River$", gnis_name))

# calculate cumulative distance along line:
flowlines_salmon <- flowlines_salmon %>% arrange(hydroseq) %>% 
  mutate(dist_zero = cumsum(lengthkm))

#flowlines_salmon %>% select(gnis_name, lengthkm, dist_zero, fromnode:hydroseq, minelevsmo, maxelevsmo, geometry) %>% View()

# basic overview
plot(flowlines_raw$geometry)
plot(flowlines_salmon$geometry, col="blue3", lwd=1.5, add=T)
plot(salmon_pts$geometry, bg="orange", pch=21, add=T, cex=4)

## plot just distance by slope?
ggplot() + geom_point(data=flowlines_salmon, aes(x=dist_zero, y=slope, fill=slope), pch=21)+
  theme_bw() + labs(x="River km from confluence", y="Slope (degrees)") +
  annotate("point", x=6.236, y=0, label="SR Forks", fill="orange", size=5, pch=21)+ # SR forks
  annotate("text", x=6.236, y=0.001, label="SR Forks") # SR forks

# with elevation
ggplot() + 
  geom_point(data=flowlines_salmon, aes(x=dist_zero, y=maxelevsmo/1000, color=slope*100), size=3.5, pch=16)+
  #geom_line(data=flowlines_salmon, aes(x=dist_zero, y=maxelevsmo/1000, color=slope*100), size=2)+
  scale_color_viridis_c("% Slope", limits=c(0,3)) +
  theme_bw() + labs(x="River distance (km from confluence)", y="Elev (m)") +
  geom_point(data=salmon_pts, aes(x=dist_zero, y=10), pch=22, size=4, fill="orange")+
  ggrepel::geom_label_repel(data=salmon_pts, aes(x=dist_zero, y=10, label=site))

ggsave(filename = "elevation_vs_riverdist_salmonriver_pts.pdf", width = 10, height = 8)

# mapview
mapview(flowlines_salmon, zcol="slope") + mapview(salmon_pts, col.regions="orange") 
# slope is based on smoothed elevations for each segment

mapview(flowlines_salmon, zcol="dist_zero") + mapview(salmon_pts, col.regions="orange") 

# Convert Line to Points --------------------------------------------------

# first convert lines to points:
flowline_pts <- st_cast(flowlines_salmon, to = "POINT") # this is quick

# or sample line for points
flowline_pts_samp <- st_sample(flowlines_salmon, size = 2000, type="regular") # gives multipt sfc

# convert back to simple points
flowline_pts_samp <- st_cast(x = st_as_sf(flowline_pts_samp), to = "POINT", split=TRUE) %>% 
  rename(geometry=x)

# compare
plot(flowline_pts$geometry[20:25], col="black", cex=4)
plot(flowline_pts_samp$geometry[1:100], col="orange", cex=2, add=T)

# mapview(flowline_pts, col.regions="black", cex=6) +
#   mapview(flowline_pts_samp, col.regions="orange", cex=4) +
#   mapview(flowlines_salmon)

# Get Elevations ----------------------------------------------------------

flowline_pts_simple <- flowline_pts %>% select(ogc_fid:comid, gnis_id:reachcode, slope, dist_zero, geometry)

# now pull elevations for these
tst_elev <- get_elev_point(flowline_pts_simple, 
                           prj = st_crs(flowline_pts_simple)$proj4string, src = "aws")
# add a seq id col
tst_elev <- mutate(tst_elev, rid=1:n())

# get distinct elev/spatial pts
distinct_pts <- tst_elev %>% st_drop_geometry() %>% distinct(comid, elevation, .keep_all = T) %>% pull(rid)

# filter orig set:
flowline_elev <- tst_elev[distinct_pts, ]

# get new dists
pts_start <- salmon_pts[1,] # start point

flowline_elev <- flowline_elev %>% 
  mutate(
    dist_to_start_m = as.vector(st_distance(pts_start, ., by_element = TRUE))
    )

# new plot
ggplot() + 
  geom_point(data=flowline_elev, aes(x=dist_zero, y=elevation, color=slope*100), size=3.5, pch=16)+
  scale_color_viridis_c("% Slope", limits=c(0,3)) +
  scale_y_continuous(breaks=c(seq(0,1500,100)))+
  scale_x_continuous(breaks = c(seq(0,80,10)))+
  theme_bw() + labs(x="River distance (km from confluence)", y="Elev (m)") +
  geom_point(data=salmon_pts, aes(x=dist_zero, y=10), pch=22, size=4, fill="orange")+
  ggrepel::geom_label_repel(data=salmon_pts, aes(x=dist_zero, y=10, label=site))

ggsave(filename = "elevation_vs_riverdist_salmonriver_pts_real_elev.pdf", width = 10, height = 8)


mapview(flowline_elev, zcol="elevation") + mapview(salmon_pts, col.regions="orange", cex=8) 
