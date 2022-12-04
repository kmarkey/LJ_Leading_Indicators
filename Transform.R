#! /usr/bin/Rscript

# libraries
library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(logger)
library(here)
library(tidyr)
library(readxl)

source("process-functions.R")

#============================== read cargs and log ============================
cargs <- commandArgs(trailingOnly = TRUE)

# parse command args and assign
parmesean(cargs)

log_setup()
log_info("Running transform.R")
#================================= first pass ==================================
# set dir
here()

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

KDAt <- read_csv("data/sour/KDAt.csv", show_col_types = FALSE)

log_info("Opened KDAt with {nrow(KDAt)} rows and {ncol(KDAt)} columns")

# verbose name change
old_names <- names(KDAt)

new_names <- c("date", "dealnum", "vstock", "caryear", "make",
             "model", "nu", "front_gross_profit", "back_gross_profit",
             "total_gross_profit", "cash_price", "pl", "sale_type",
             "salesman", "salesmanager", "fimanager")

if (length(old_names) == length(new_names)) {
  KDAt <- rename_at(KDAt, old_names, ~ new_names)
  
} else {
  log_warn("Cannot change column names")
}

log_trace("Juggling numeric columns")

# clean all and make numeric
KDAt <- mutate(KDAt, across(c(front_gross_profit,
                          back_gross_profit,
                          total_gross_profit,
                          cash_price), 
                          pear),
                 date = as.Date(date, format = "%m/%d/%Y")) # change date

#======================- create model year variable ============================
# highest possible model year = current year + 1, assuming age < 100
max_model_year <- as.numeric(substr(year(Sys.Date()) + 1, 3, 4))

KDAt <- KDAt %>%
  
  mutate(caryear = as.numeric(
    ifelse(str_length(caryear) == 1, str_c("200", caryear), 
                       ifelse(str_length(caryear) == 2 & caryear > max_model_year, str_c("19", caryear),
                              str_c("20", caryear))))
  ) %>%
  arrange(date)

#================================= date bounds =================================
log_trace("Fencing in dates")

# this isn't going to change
# first eligible date 
if (min(KDAt$date) == as.Date("2010-01-02")) {
  min_date <- min(KDAt$date) - 1 # first day is the 1st of the month?
} else { # should never happen
log_warn("Error synchronizing dates??")
}

# last eligible date
if (max(KDAt$date) == ceiling_date(max(KDAt$date), unit = "month") - 1) {
  max_date <- max(KDAt$date) # last day is last of the month?
  
} else { # else get last full month
  max_date <- floor_date(max(KDAt$date), unit = "month") - 1
}

log_info("Data available from {min_date} to {max_date}")

#================================ by month =====================================
# no imputation
log_trace("Grabbing months")

# get month totals
month_all <- KDAt %>%
  
  group_by(date = floor_date(date, unit = "month"), .drop = FALSE) %>%
  
  dplyr::filter(date <= max_date, date >= min_date) %>%
  
  mutate(fgp = sum(front_gross_profit, na.rm = T),
         tgp = sum(total_gross_profit, na.rm = T),
         cp = sum(cash_price, na.rm = T),
         n = n(),
         fgp_a = sum(front_gross_profit, na.rm = T)/n(),
         tgp_a = sum(total_gross_profit, na.rm = T)/n(),
         cp_a = sum(cash_price, na.rm = T)/n(),
         new_n = sum(ifelse(nu == "NEW", 1, 0), na.rm = T),
         used_n = sum(ifelse(nu == "USED", 1, 0), na.rm = T)) %>%
  
  summarise(date, n, fgp, tgp, cp, fgp_a, tgp_a, cp_a, new_n, used_n) %>%
  
  ungroup() %>%
  
  distinct()

if (sum(is.na(month_all)) > 0) {
  log_warn("{sum(is.na(month_all))} values missing from month_all!")
} else {
  log_info("month_all is pristine")
  }
#============================= seasonal adjustment =============================
# slight seasonal adj?

log_trace("No seasonal adjustment")

log_trace("Saving monthly data")

write_csv(month_all, "./data/out/month_all.csv")

log_info("End transform.R")