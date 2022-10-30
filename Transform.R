# Running Questions

# Which ones would be best to track? Which is the best indicator of overall business performance?
# How can we ingest lots more data?
# Local data?

# Summed up values per day?


# find covid cutoff

library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(mice)
library(logger)
library(here)
library(tidyr)
library(readxl)
#================================= first pass ==================================

options(warn = -1)

# set dir
here()

log_info("Gently tucking the data in for a nap")

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

KDAt <- read_csv("data/sour/KDAt.csv")

log_info("Opened KDAt with {nrow(KDAt)} rows and {ncol(KDAt)} columns")

# verbose is safer
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

# remove character class and change parsing
pear <- function(x) {
  x <- gsub("[()\\s,]", "", x)
  x <- as.numeric(x)
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
log_warn("Error fetching dates??")
}

# last eligible date
if (max(KDAt$date) == ceiling_date(max(KDAt$date), unit = "month") - 1) {
  max_date <- max(KDAt$date) # last day is last of the month?
  
} else { # else get last full month
  max_date <- floor_date(max(KDAt$date), unit = "month") - 1
}

log_info("Data available from {min_date} to {max_date}")

#==============================- day summaries =================================
# Roll up by day and by day per sale
# daily sums
# day_sum <- group_by(KDAt, date) %>%
#   mutate(fgp = sum(front_gross_profit, na.rm = T),
#          tgp = sum(total_gross_profit, na.rm = T),
#          cp = sum(cash_price, na.rm = T),
#          n = length(nu)) %>%
#   summarise(date, fgp, tgp, cp, n) %>%
#   distinct()
# 
# #daily average per sale
# day_avg <- group_by(KDAt,date) %>%
#   mutate(fgp_a = sum(front_gross_profit)/n(),
#          tgp_a = sum(total_gross_profit)/n(),
#          cp_a = sum(cash_price)/n()) %>%
#   ungroup() %>%
#   summarise(date, fgp_a, tgp_a, cp_a) %>%
#   distinct()
# 
# day_partial <- full_join(day_sum, day_avg, by = "date")
# 
# # Need to trim dates and impute
# time_seq <- tibble(date = seq.Date(from = min(KDAt$date), 
#                                 to = max_date, by = 'day')) # should be current date eventually
# 
# day <- left_join(time_seq, day_partial, by = "date") %>%
#   dplyr::select(date, n, tgp_a, cp_a)
# 
# # missing days using PMM
# imp <- mice(data = day, print = F)
# day_1_c <- complete(imp)
# 
# missingcheck <- sum(is.na(day_1_c)) == 0L
# 
# # add lead for 6 months?
# day_1_c <- left_join(
#   tibble(date = seq.Date(from = as.Date(min_date), 
#                                      to = as.Date("2020-11-16"), by = 'day')),
#   day_1_c, by = "date")

# completed imputation on values of
# log_info(
#   "Completed daily imputation on: \n {sum(is.na(day$n))} values of n\n {sum(is.na(day$tgp_a))} values of tgp_a\n {sum(is.na(day$cp_a))} values of cp_a"
# )

#============================= now by month ====================================
# no imputation
log_trace("Grabbing months")

# get nu totals
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
         new_n = sum(ifelse(nu == "NEW", 1, 0)),
         used_n = sum(ifelse(nu == "USED", 1, 0))) %>%
  summarise(date, n, fgp, tgp, cp, fgp_a, tgp_a, cp_a, new_n, used_n) %>%
  distinct()

# wrong dimensions gets fixed later
# month_n <- month_nu %>%
#   dplyr::filter(nu == "NEW") %>%
#   ungroup() %>%
#   dplyr::select(-nu)
# 
# month_u <- month_nu %>%
#   dplyr::filter(nu == "USED") %>%
#   ungroup() %>%
#   select(-nu)
# 
# # select important vars and stop date for COVID
# month_pre <- filter(month_all, date <= covid_cutoff, date <= max_date) %>%
#   dplyr::select(date, n, tgp_a, cp_a) %>%
#   arrange(date)
# 
# month_post <- filter(month_all, date > covid_cutoff, date <= max_date) %>%
#   dplyr::select(date, n, tgp_a, cp_a) %>%
#   arrange(date)

#============================= seasonal adjustment =============================
# slight seasonal adj?
log_trace("No seasonal adjustment")

log_info("Saving data")

write_csv(month_all, "./data/out/month_all.csv")
