#! /usr/bin/Rscript
# using renv

# setup
library(reticulate)
renv::use_python()

# params
cor_max <- 0.20 # set feature correlation cutoff
ahead <- 3 # set lead time in months
train_set <- "all" # data subset being used
targetvar <-  "n" # variable of interest
bloat <- FALSE # favor wide over long feature data


source("scripts/transform.R")

source("scripts/fishing.R")

# fetch data if necessary
source_python("scripts/fetch.py")

source("scripts/collage.R")
