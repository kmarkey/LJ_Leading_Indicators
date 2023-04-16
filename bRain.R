#! /usr/bin/Rscript

# R brain
library(reticulate)

cor_max <- 0.20 # set feature correlation cutoff
ahead <- 3 # set lead time in months
train_set <- "all" # data subset being used
targetvar <-  "n" # variable of interest
bloat <- FALSE # favor wide over long feature data


# source("transform.R")

source("fishing.R")

# fetch data if necessary
source_python("thon/fetch.py", envir = NULL)

source("collage.R")



