# 03_read_mdw_database

library(Hmisc)
library(tidyverse)
library(fs)
library(here)
library(RSQLite)

# get database path:
mdblink <- as_fs_path(paste0(here(), "/data/Fen_Meadows_Shasta_Trinity.mdb"))

# see table names:
(mDB <- mdb.get(mdblink, tables=TRUE))

# get single table
features <- mdb.get(mdblink, tables="Features", stringsAsFactors=F) 

# drop the "attributes" component that gets added to the dataframe (annoying but won't cause trouble)

# Here's a function to remove the attrs:
clear.labels <- function(x) {
  if(is.list(x)) {
    for(i in 1 : length(x)) class(x[[i]]) <- setdiff(class(x[[i]]), 'labelled') 
    for(i in 1 : length(x)) attr(x[[i]],"label") <- NULL
  }
  else {
    class(x) <- setdiff(class(x), "labelled")
    attr(x, "label") <- NULL
  }
  return(x)
}

# now run the function
features<- clear.labels(features)
