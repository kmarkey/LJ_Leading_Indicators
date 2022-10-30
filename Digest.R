#===============================================================================
# Home sales
# Consumer confidence index
# Interest Rates
# appointments
# Total vehicle sales retail SAAR (check between)
# SAAR in washington, King/Snohomish, cross-sell
# Google "car" searches

# Natural Rate of unemployment (short-term)

# work in python to download online data

library(dplyr)
library(tidyr)
library(readr)
library(logger)
library(here)
library(rlang)

here()

################# gets vars from Collage.R
# change so this cript just selects targetvar and filters date range

# From Quandl, monthly observations don't come on the 1st
# Lag months and then filter to interval of nrow(month)

log_info("Chewing on parameters")
# read in month?
month_all <- read_csv("./data/out/month_all.csv")
#===============================================================================
# set search date boundaries


#=========================== data partitions ===================================
# Feb is the last full month
covid_cutoff <- ceiling_date(as.Date("2020-03-26") - months(1), unit = "month") - 1
old_cutoff <- as.Date("2015-12-31")


if (train_set == "pre-covid") {
  log_info("Using pre-covid data before COVID-19 cutoff date {covid_cutoff}")
  month <- dplyr::filter(month_all, date <= covid_cutoff)
  
} else if (train_set == "post-covid") {
  log_info("Using post-covid data after COVID-19 cutoff date {covid_cutoff}")
  month <- dplyr::filter(month_all, date > covid_cutoff)
    
} else if (train_set == "oldest") {
  log_info("Using older data before {covid_cutoff}")
  month <- dplyr::filter(month_all, date <= old_cutoff)
  
} else if (train_set == "newest") {
  log_info("Using newer data after {covid_cutoff}")
  month <- dplyr::filter(month_all, date > old_cutoff)
  
} else {
  log_info("Using full dataset")
  month <- month_all
}

month <- dplyr::select(month, all_of(targetvar), date)

log_info("Proceeding with {nrow(month)} values of {targetvar}")

#=========================== data search bounds ================================
#### not sure if using these
search_bottom <- min(month$date) - years(1) # from month

# expect full most recent month
search_top <- max(month$date)

log_info("Setting search lbound to {search_bottom} ubound to {search_top}")

lead_bottom <- search_top - years(1)
lead_top <- search_top # 3 months ahead

# write out
boundlist <- tibble(search_bottom = search_bottom,
                    search_top = search_top,
                    lead_bottom = lead_bottom,
                    lead_top = lead_top) 

# blank df for feature prep
blank_m <- tibble(date = seq.Date(from = search_bottom, to = search_top, by = "month"))

log_trace("Search bounds and blank_m saved!")


# replace all NAs with 0s
mylist <- list()

for (avar in targetvar) {
  mylist[[avar]] = 0
}

if (sum(is.na(month)) > 0) {
  log_error("A fire is starting! Missing values of {targetvar}!")
  month <- month %>%
    replace_na(0)
}


# log_info("Added {nrow(month) - mrow} months and replaced {sum(nrow(month) - mrow, is.na(month))} value with 0")

write_csv(blank_m, "./keys/blank_m.csv")
