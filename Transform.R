# Running Questions

# Which ones would be best to track? Which is the best indicator of overall business performance?
# How can we ingest lots more data?
# Local data?

# Summed up values per day
# Prepared a month, 2-month, quarter, and 2-quarter lead


# find max_date

library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(mice)
#------------------------- warnings suppressed ---------------------------------
options(warn = -1)

# set dir
setwd("~/LocalRStudio/LJ_Leading_Indicators")

# read in raw
KDAt <- read_csv("data/Keaton Data Analysis Project-2016-2020.csv",
                   na = c("", "-", "--", "---", "	 -   ", " -   ", " ", "  "), 
                   skip = 1, trim_ws = TRUE, col_names = TRUE)

# verbose is safer
old_names <- names(KDAt)
new_names <- c("date", "dealnum", "vstock", "caryear", "make",
             "model", "nu", "front_gross_profit", "back_gross_profit",
             "total_gross_profit", "cash_price", "pl", "sale_type",
             "salesman", "salesmanager", "fimanager")
KDAt <- rename_at(KDAt, old_names, ~ new_names)

# remove character class and change parsing
pear <- function(x) {
  x <- gsub("[()\\s,]", "", x)
  x <- as.numeric(x)
}

# clean all and make numeric
KDAt <- mutate(KDAt, across(c(front_gross_profit,
                          back_gross_profit,
                          total_gross_profit,
                          cash_price), 
                          pear),
                 date = as.Date(date, format = "%m/%d/%Y")) # change date

#----------------------- create model year variable ----------------------------
# highest possible model year = current year + 1, assuming age <100
max_year <- as.numeric(substr(year(Sys.Date()) + 1, 3, 4))

KDAt <- KDAt %>%
  mutate(caryear = as.numeric(
    ifelse(str_length(caryear) == 1, str_c("200", caryear), 
                       ifelse(str_length(caryear) == 2 & caryear > max_year, str_c("19", caryear),
                              str_c("20", caryear))))
  )

# current data bounds specs
min_date <- min(KDAt$date) - 365 # lowest possible date including 12-month lag

# stop date for training split
end_date <- as.Date("2020-03-26") # pre covid
# Feb is the last full month
max_date <- ceiling_date(end_date - months(1), unit = "month")


# check formats
classcheck <- class(KDAt$date) == "Date" & class(KDAt$front_gross_profit) == "numeric"

# order by date
KDAt <- KDAt %>%
  arrange(date)

#------------------ plots + summaries have been moved --------------------------

# Roll up by day and by day per sale
# lots of missing days
# daily sums
day_sum <- group_by(KDAt, date) %>%
  mutate(fgp = sum(front_gross_profit, na.rm = T),
         tgp = sum(total_gross_profit, na.rm = T),
         cp = sum(cash_price, na.rm = T),
         n = length(nu)) %>%
  summarise(date, fgp, tgp, cp, n) %>%
  distinct()

#daily average per sale
day_avg <- group_by(KDAt,date) %>%
  mutate(fgp_a = sum(front_gross_profit)/n(),
         tgp_a = sum(total_gross_profit)/n(),
         cp_a = sum(cash_price)/n()) %>%
  ungroup() %>%
  summarise(date, fgp_a, tgp_a, cp_a) %>%
  distinct()

day_partial <- full_join(day_sum, day_avg, by = "date")

# Need to trim dates and impute
time_seq <- tibble(date = seq.Date(from = min(KDAt$date), 
                                to = end_date, by = 'day')) # should be current date eventually

day <- left_join(time_seq, day_partial, by = "date") %>%
  dplyr::select(date, n, tgp_a, cp_a)

# missing days using PMM
imp <- mice(data = day, print = F)
day_1_c <- complete(imp)

missingcheck <- sum(is.na(day_1_c)) == 0L

# create lags for day
# lead y as opposed to lagging x
lead_1 <- 30 # 1 month
lead_2 <- 60 # 2 months
lead_3 <- 90 # 3 months
lead_6 <- 180 # 6 months
lead_12 <- 360 # 12 months

# add lead for 6 months?
day_1_c <- left_join(
  tibble(date = seq.Date(from = min_date, 
                                     to = as.Date("2020-11-16"), by = 'day')),
  day_1_c, by = "date")

# completed imputation on values of
cat("Completed imputation on", sum(is.na(day$n)), "values of n\n")
cat("Completed imputation on", sum(is.na(day$tgp_a)), "values of tgp_a\n")
cat("Completed imputation on", sum(is.na(day$cp_a)), "values of cp_a\n")

#----------------------------- now by month ------------------------------------
# no imputation

month_sum <- KDAt %>%
  dplyr::filter(date < max_date) %>% # stop at max_date
  group_by(date = floor_date(date, unit = "month")) %>%
  mutate(fgp = sum(front_gross_profit, na.rm = T),
         tgp = sum(total_gross_profit, na.rm = T),
         cp = sum(cash_price, na.rm = T),
         n = n()) %>%
  ungroup() %>%
  summarise(date, fgp, tgp, cp, n) %>%
  distinct()

# monthly average per sale
month_avg <- KDAt %>%
  dplyr::filter(date < max_date) %>% # stop at max_date
  group_by(date = floor_date(date, unit = "month")) %>%
  mutate(fgp_a = sum(front_gross_profit, na.rm = T)/n(),
         tgp_a = sum(total_gross_profit, na.rm = T)/n(),
         cp_a = sum(cash_price, na.rm = T)/n()) %>%
  ungroup() %>%
  summarise(date, fgp_a, tgp_a, cp_a) %>%
  distinct()

month_partial <- left_join(month_sum, month_avg, by = "date")

# select important vars and stop date for COVID
month <- filter(month_partial, date <= max_date) %>% ##### change date in future v.s
  dplyr::select(date, n, tgp_a, cp_a) %>%
  arrange(date)

#----------------------------- seasonal adjustment -----------------------------
# slight seasonal adj
  
write_csv(month, "./data/out/month.csv")

######## make blank df for joining ########################################
# Fix blanks
# blank_d <- dplyr::select(day_lead, date)  ### refer to raw df dates
# blank_m <- dplyr::select(month_lead, date)))
