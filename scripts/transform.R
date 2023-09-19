#! /usr/bin/Rscript

# libraries
library(dplyr, quietly = TRUE)
library(readr)
library(stringr)
library(lubridate, quietly = TRUE)
library(logger)
library(here)
library(tidyr)
library(readxl)

#============================== read cargs and log =============================

if(!exists("utilities_loaded")) source("./scripts/utilities.R")

log_setup()

log_info("Running transform.R")

# cargs <- commandArgs(trailingOnly = TRUE)

# parse command args and assign
# parmesean(cargs)

#================================= first pass ==================================
# set dir

source("./scripts/bucket.R")

log_info("Opened KDAc with {nrow(KDAc)} rows and {ncol(KDAc)} columns")

#================================= date bounds =================================
log_trace("Fencing in dates")

# this isn't going to change
# first eligible date 
if (min(KDAc$date) == as.Date("2010-01-02")) {
    
    min_date <- min(KDAc$date) - 1 # first day is the 1st of the month?
    
} else { # should never happen
    
    log_warn("Error synchronizing dates??")
    
}

# last eligible date
if (max(KDAc$date) == ceiling_date(max(KDAc$date), unit = "month") - 1) {
    
    max_date <- max(KDAc$date) # last day is last of the month?
    
} else { # else get last full month
    
    max_date <- floor_date(max(KDAc$date), unit = "month") - 1
    
}

log_info("Data available from {min_date} to {max_date}")

#================================ by month =====================================

# no imputation
log_trace("Grabbing months")

# get month totals
month_all <- KDAc %>%
  
  group_by(date = floor_date(date, unit = "month"), .drop = FALSE) %>%
  
  dplyr::filter(date <= max_date, date >= min_date) %>%
  
  transmute(
    date = date,
    fgp = sum(front_gross_profit, na.rm = T),
    tgp = sum(total_gross_profit, na.rm = T),
    cp = sum(cash_price, na.rm = T),
    n = n(),
    fgp_a = sum(front_gross_profit, na.rm = T) / n(),
    tgp_a = sum(total_gross_profit, na.rm = T) / n(),
    cp_a = sum(cash_price, na.rm = T) / n(),
    new_n = sum(ifelse(nu == "NEW", 1, 0), na.rm = T),
    used_n = sum(ifelse(nu == "USED", 1, 0), na.rm = T)
  ) %>%
  
  ungroup() %>%
  
  distinct()

if (sum(is.na(month_all)) > 0) {
    
    log_warn("{sum(is.na(month_all))} values missing from month_all!")
    
} else {
    
    log_info("month_all is pristine")
    
}

log_trace("Saving monthly data")

write_csv(month_all, "./data/out/month_all.csv")

log_success("End transform.R")
