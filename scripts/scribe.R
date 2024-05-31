#! /usr/bin/Rscript

# after new data is read, records some params in json and sets up dfs for fill and join
#===============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(logger)
library(here)
library(rlang)

if (!exists("utilities_loaded"))
  source("./scripts/r_utilities.R")

log_setup()

log_info("Running scribe")

# read in month_all?
if (!exists("month_all")) {
    
    month_all <- read_csv("./data/out/month_all.csv", show_col_types = FALSE)
    
    log_info("Read in month_all")
    
    }

#=========================== set wolf var ======================================

# deprecated splitting
covid_cutoff <- ceiling_date(as.Date("2020-03-26") - months(1), unit = "month") - 1

dreq_cutoff <- as.Date("2015-12-31")

if (train_set == "pre-covid") {
    
    log_info("Using pre-covid data before COVID-19 cutoff date {covid_cutoff}")
    
    wolf <- dplyr::filter(month_all, date <= covid_cutoff)
    
} else if (train_set == "post-covid") {
    
    log_info("Using post-covid data after COVID-19 cutoff date {covid_cutoff}")
    
    wolf <- dplyr::filter(month_all, date > covid_cutoff)
    
} else if (train_set == "oldest") {
    
    log_info("Using older data before {covid_cutoff}")
    
    wolf <- dplyr::filter(month_all, date <= dreq_cutoff)
    
} else if (train_set == "newest") {
    
    log_info("Using newer data after {covid_cutoff}")
    
    wolf <- dplyr::filter(month_all, date > dreq_cutoff)
    
} else {
    
    log_info("Using full dataset")
    
    wolf <- month_all
  
}

# wolf is target var plucked from KDA
wolf <- dplyr::select(wolf, all_of(targetvar), date)

log_info("Proceeding with {nrow(wolf)} values of {targetvar}")

#=========================== data search bounds ================================

search_bottom <- min(wolf$date) - years(1) # from month

# expect full most recent month
search_top <- ceiling_date(max(wolf$date), unit = "month") - 1

log_info("Set lower search bound to {search_bottom} upper search bound to {search_top}")

# blank df for feature prep
blank_m <- tibble(date = seq.Date(from = search_bottom, to = search_top, by = "month"))

rundata <- list(date = Sys.Date(),
             targetvar = targetvar,
             ahead = ahead,
             cor_max = cor_max,
             search_bottom = search_bottom,
             search_top = search_top)

jsonlite::write_json(rundata, paste0("./logs/", Sys.Date(), "/params.log"))

log_trace("Search bounds and blank_m saved!")

if (sum(is.na(wolf)) > 0) {
    
    log_error("Missing values of {targetvar}!")
    
    wolf <- wolf %>%
        
        replace_na(0)
}

#================================== save =======================================
write_csv(blank_m, "./keys/blank_m.csv")

write_csv(wolf, "./data/in/wolf.csv")

log_info("wolf and blank_m saved")

log_info("End fishing.R")

rm(month_all, blank_m)
