# an example of extraction with stars_rasters
# from here: https://luisdva.github.io/rstats/GIS-with-R/


# Packages ----------------------------------------------------------------

library(sf) # Simple Features for R
library(rnaturalearth) # World Map Data from Natural Earth
library(here) # A Simpler Way to Find Your Files
library(stars) # Spatiotemporal Arrays, Raster and Vector Data Cubes
library(dplyr) # A Grammar of Data Manipulation
library(ggplot2) # Create Elegant Data Visualisations Using the Grammar of Graphics
library(ggnewscale) # Multiple Fill and Color Scales in 'ggplot2'
library(scico) # Colour Palettes Based on the Scientific Colour-Maps
library(geobgu) # install from GitHub devtools::install_github("michaeldorman/geobgu")
library(ggrepel) # Automatically Position Non-Overlapping Text Labels with 'ggplot2'


# Load Rasters ------------------------------------------------------------

# get data: https://datadryad.org/stash/dataset/doi:10.5061/dryad.052q5

# load raster
humanFp <- read_stars("path-to-the-data/HFP2009.tif")

# world map
worldmap <- ne_countries(scale = "small", returnclass = "sf")
mesoam <- worldmap %>%
  filter(region_wb == "Latin America & Caribbean" &
           subregion != "South America" &
           subregion != "Caribbean") %>%
  select(admin) %>%
  st_transform("+proj=moll")

# species ranges
mammalpolys <- st_read("path-to-the-data/TERRESTRIAL_MAMMALS.shp")
primate_polys <- filter(mammalpolys, order_ == "PRIMATES") %>% st_transform("+proj=moll")


# crop the raster
hfp_meso <- st_crop(humanFp, mesoam)
plot(hfp_meso)


# Mesoamerican species
primates_meso <- st_intersection(primate_polys, mesoam)
primates_meso <- primates_meso %>%
  group_by(binomial) %>%
  summarize()
# country outlines
divpol <-
  worldmap %>%
  filter(region_un == "Americas") %>%
  select(admin) %>%
  st_transform("+proj=moll")

# plotting limits
limsMeso <- st_bbox(st_buffer(primates_meso, 20000))
# species labels
labelling <- primates_meso %>% st_centroid()
labelling <- labelling %>% mutate(X = st_coordinates(labelling)[, 1], Y = st_coordinates(labelling)[, 2])


ggplot() +
  geom_sf(data = primates_meso, aes(fill = binomial), alpha = 0.5, color = "black", size = 0.4) +
  facet_wrap(~binomial) +
  geom_sf(data = divpol, color = "gray", fill = "transparent", size = 0.2, alpha = 0.5) +
  coord_sf(
    xlim = c(limsMeso["xmin"], limsMeso["xmax"]),
    ylim = c(limsMeso["ymin"], limsMeso["ymax"])
  ) +
  scale_fill_scico_d(name = "Scientific name", palette = "hawaii") +
  theme_minimal() + theme(
    strip.text = element_text(face = "italic"),
    legend.text = element_text(face = "italic")
  )


primates_meso <-
  primates_meso %>% mutate(
    hfpMean = raster_extract(hfp_meso, primates_meso, fun = mean, na.rm = TRUE),
    hfpMax = raster_extract(hfp_meso, primates_meso, fun = max, na.rm = TRUE),
    hfpMin = raster_extract(hfp_meso, primates_meso, fun = min, na.rm = TRUE)
  )
primates_meso %>%
  st_set_geometry(NULL) %>%
  knitr::kable()



ggplot() +
  geom_sf(data = divpol, color = "gray", fill = "light grey") +
  geom_stars(data = hfp_meso, downsample = 10) +
  scale_fill_scico(
    palette = "lajolla", na.value = "transparent",
    name = "Human Footprint",
    guide = guide_colorbar(
      direction = "horizontal",
      title.position = "top"
    )
  ) +
  guides(fill = guide_colorbar(title.position = "top")) +
  new_scale_fill() +
  geom_sf(data = primates_meso, aes(group = binomial), color = "black", fill = "blue", alpha = 0.01) +
  geom_sf(data = divpol, color = "black", fill = "transparent", size = 0.1) +
  geom_text_repel(data = labelling, aes(X, Y, label = binomial), alpha = 0.5, fontface = "italic") +
  hrbrthemes::theme_ipsum_ps() + labs(x = "", y = "") +
  coord_sf(
    xlim = c(limsMeso["xmin"], limsMeso["xmax"]),
    ylim = c(limsMeso["ymin"], limsMeso["ymax"])
  ) +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  theme(
    legend.position = c(0.2, 0.1),
    panel.background = element_rect(fill = "#EAF7FA"),
    panel.border = element_rect(colour = "black", fill = "transparent"),
    legend.background = element_rect(fill = "white")
  )


ggplot()+
  geom_sf(data=divpol,color="gray",fill="light grey")+
  geom_stars(data = hfp_meso,downsample = 10) +
  scale_fill_scico(palette = "lajolla",na.value="transparent",
                   name="Human Footprint",
                   guide = guide_colorbar(
                     direction = "horizontal",
                     title.position = 'top'
                   ))+
  guides(fill= guide_colorbar(title.position = "top"))+
  new_scale_fill()+
  geom_sf(data=primates_meso,aes(group=binomial,fill=binomial),color="black",alpha=0.8)+
  scale_fill_brewer(type = "qual")+
  facet_wrap(~binomial)+
  geom_sf(data=divpol,color="black",fill="transparent",size=0.1)+
  hrbrthemes::theme_ipsum_ps() + labs(x="",y="")+
  coord_sf(xlim = c(limsMeso["xmin"], limsMeso["xmax"]), 
           ylim = c(limsMeso["ymin"], limsMeso["ymax"]))+
  scale_x_discrete(expand=c(0,0))+
  scale_y_discrete(expand=c(0,0))+
  theme(legend.position = c(0.6, 0.1),
        panel.background = element_rect(fill="#EAF7FA"),
        panel.border = element_rect(colour = "black",fill = "transparent"),
        legend.background = element_rect(fill = 'white'),
        strip.text = element_text(face = "italic"))