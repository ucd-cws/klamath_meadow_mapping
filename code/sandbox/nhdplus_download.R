
# https://cran.r-project.org/web/packages/nhdplusTools/vignettes/nhdplusTools.html#discovery_subsetting
library(nhdplusTools)
library(sf)

nhd_dir <- "../../GIS/layers/NHDPlus/"

# To download at the HUC4 scale
#download_nhdplushr(nhd_dir = nhd_dir,
#                   hu_list = c("180101"),
#                   download_files = T)


HUC4 <- "../../GIS/layers/NHDPlus/1801/NHDPLUS_H_1801_HU4_GDB.gdb"

