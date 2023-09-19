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
  
  # # file to join with x
  # KDAt <- read_csv(whole_file_path, show_col_types = FALSE)
  # 
  # can csv?
  if (grepl("\\.csv$", x)) {
    
    adata <- read_csv(x, show_col_types = FALSE)
    
  # can xlsx?
  } else if (grepl("\\.xlsx$", x)) {
    
    adata <- read_xlsx(
      x,
      na = c("", "-", "==", "==-", "	 -   ", " -   ", " ", "  "),
      skip = 1,
      trim_ws = TRUE,
      col_names = TRUE)
    
    dummy_row <- structure(list(SOLD = structure(NA_real_, tzone = "UTC", class = c("POSIXct", 
                                                                                    "POSIXt")), `DEAL-NO` = NA_character_, `VEHICLE-STOCK-NO...` = NA_character_, 
                                YEAR = NA_real_, MAKE = NA_character_, MODEL = NA_character_, 
                                NU = NA_character_, COMMONSALEDEALER = "Front Gross Profit", 
                                BACKGPESTIMATE.. = "Back Gross Profit", TOTALCOMMDEALER.. = "Total Gross Profit", 
                                `CASH-PRICE` = NA_real_, PL = NA_character_, `SALE-TYPE` = NA_character_, 
                                SALESMAN = NA_character_, SALESMANAGER = NA_character_, FIMANAGER = NA_character_), row.names = c(NA, 
                                                                                                                                  -1L), class = c("tbl_df", "tbl", "data.frame"))
    
    # possibly skip 2 lines
    if (sum(dummy_row == adata[1,], na.rm = TRUE) > 0) {
      
      adata <- read_xlsx(
        x,
        na = c("", "-", "==", "==-", "	 -   ", " -   ", " ", "  "),
        skip = 2,
        trim_ws = TRUE,
        col_names = TRUE,
        col_types = c("date", "numeric", "text", "numeric", "text", "text", "text", "numeric", "numeric", "numeric", "numeric", "text", "text", "text", "text", "text"))
      
    }
  } else {
      
      log_info("No eligible files in bucket, reading most recent file")
      
      # read in clean file
    ###### change to most recent by default#########
      maxfile_date <- max(as.Date(
        str_extract(list.files("data/sour/", pattern = "^KDAc"), pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}")
      ), na.rm = TRUE)
      
      maxfile_path <- paste0("./data/sour/KDAc-", maxfile_date, ".csv")
      
      KDAc <- read_csv(maxfile_path, show_col_types = FALSE)
          
      break
  }
  
  # has names?
  testit::assert("File doesn't have column names", !is.null(attr(adata, "names")))
  
  # same number of names?
  if (length(colnames(KDAc)) == length(colnames(adata))) {
    
    # apply clean KDA
    adata <- clean_kda(adata)
    
    # check overlap
    # if less than one day of difference
    if ((max(KDAc$date) - min(adata$date)) < 1) {
      
      
    } else {
      log_info("Temporal mismatch between old and new, favoring old data")
      
      adata <- adata %>%
        dplyr::filter(date > max(KDAc$date))
      # KDAc <- KDAt
    }
    
    KDAc_new <- bind_rows(KDAc, adata) %>%
      dplyr::arrange(date)
    
    # write out
    log_info("writing out new KDAc")
    
    write_csv(KDAc_new, paste0("./data/sour/KDAc-", Sys.Date(), ".csv"))
    
    # remove from bucket
    
    log_trace("Removing old KDAt and clearing bucket")
    
    # copy and remove bucket files
    file.copy(from = x,
              to = "./data/sour/")
    
    file.remove(x)
    
    rm(adata)
    
    # set env as newest KDAc
    KDAc <- KDAc_new
  
    # and save file
    write_csv(KDAc, "./data/sour/KDAc.csv")
    
      } else {
    
    log_info("Inconsistent column names, can't update")
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
# 
# pred_file_list <- list.files("./models/dev/prediction/snapshots/", pattern = "l-full.*.csv")
# 
# for (file in pred_file_list) {
#   full_join()
# }
# pred_file_list