#! /usr/bin/Rscript

library(readxl)
library(tidyverse)

if(!exists("utilities_loaded")) source("./scripts/utilities.R")

log_setup()

#in the bin
log_info("Pouring bucket")

# check file eligibility
bucket_path <- "./data/sour/bucket/"

# pointer to whole file
whole_file_path <- "./data/sour/KDAt.csv"

# list of csv files in path
file_list <- paste0(bucket_path, list.files(bucket_path))

# for each file name
for (x in file_list) {

  KDAt <- read_csv(whole_file_path, show_col_types = FALSE)
  
  # can csv?
  if (grepl("\\.csv$", x)) {
    adata <- read_csv(x, show_col_types = FALSE)
    
  } else if (grepl("\\.xlsx$", x)) {
    adata <- read_xlsx(
      x,
      na = c("", "-", "==", "==-", "	 -   ", " -   ", " ", "  "),
      skip = 1,
      trim_ws = TRUE,
      col_names = TRUE
    )
    
  } else {
    log_info("No eligible files in bucket")
    
    KDAc <- read_csv("./data/sour/KDAt.csv", show_col_types = FALSE) %>%
      clean_kda()
      
    break
  }
  
  testit::assert("File doesn't have column names",!is.null(attr(adata, "names")))
  
  if (all(colnames(KDAt) == colnames(adata))) {
    
    KDAt <- clean_kda(KDAt)
    
    # append data
    adata <- clean_kda(adata)
    
    if (max(KDAt$date) < min(adata$date)) {
      log_trace("Binding rows in bucket")
      
      KDAc <- bind_rows(KDAt, adata) %>%
        dplyr::arrange(date)
      
    } else {
      log_trace("Temporal overlap between new and old")
      
      KDAc <- KDAt
    }
    
    # write out
    log_info("writing over KDAc")
    
    write_csv(KDAc, paste0("./data/sour/KDAc-", Sys.Date(), ".csv"))
    
    # remove from bucket
    
    log_trace("Removing old KDAt")
    
    file.remove(x)
    
    rm(KDAt, adata)
  }
  
}

# read in raw
# KDA_2016 <- read_xlsx("data/sour/Keaton Data Analysis Project-2016-2020.xlsx",
#                    na = c("", "-", "==", "==-", "	 -   ", " -   ", " ", "  "),
#                    skip = 1, trim_ws = TRUE, col_names = TRUE)
#
# KDA_2010 <- read_xlsx("data/sour/Markey Project 010110-123110.xlsx", skip = 1,
#                       na = c("", "-", "==", "==-", "	 -   ", " -   ", " ", "  "),
#                       trim_ws = TRUE, col_names = TRUE)
#
# KDA_2011 <- read_xlsx("data/sour/Markey Project 010111-123115.xlsx", skip = 1,
#                       na = c("", "-", "==", "==-", "	 -   ", " -   ", " ", "  "),
#                       trim_ws = TRUE, col_names = TRUE)
#
# KDA_2022 <- read_xlsx("data/sour/Markey Project 110120-093022.xlsx", skip = 1,
#                       na = c("", "-", "==", "==-", "	 -   ", " -   ", " ", "  "),
#                       trim_ws = TRUE, col_names = TRUE)
#
