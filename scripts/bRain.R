#! /usr/bin/Rscript
# using renv

# setup
library(reticulate)

renv::use_python("renv/python/virtualenvs/renv-python-3.10/Scripts/python.exe")

# params
cor_max <- 0.15 # set feature correlation cutoff
ahead <- 6 # set lead time in months
train_set <- "all" # data subset being used
targetvar <-  "n" # variable of interest
bloat <- FALSE # favor wide over long feature data

# version of KDAc??
source("scripts/transform.R")

source("scripts/scribe.R")

# fetch data if necessary
reticulate::source_python("scripts/fetch.py")

source("scripts/collage.R")

reticulate::source_python("models/dev/scripts/predict_all.py")
