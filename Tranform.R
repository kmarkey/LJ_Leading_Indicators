# Running Questions

# Which ones would be best to track? Which is the best indicator of overall business performance?
# How can we ingest lots more data? Can we get local data?

# COnditions
# Used all good data, no collinearity
# Summed up values per day
# Prepared a month, 2-month, quarter, and 2-quarter lead
# More obs than features--good or bad?

library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(glmnet)
library(mice)

####################################################################### warnings suppressed
options(warn = -1)
#set dir ???????????????????????????????????????????
setwd("~/LocalRStudio/LJ_Leading_Indicators")
#read in raw
KDARaw <- read_csv("data/Keaton Data Analysis Project-2016-2020.csv",
                   na = c("", "-", "--", "---", "	 -   ", " -   ", " ", "  "), 
                   skip = 1, trim_ws = TRUE, col_names = TRUE) ## request from SQL?
#vrbose is safer
o_names <- names(KDARaw)
n_names <- c("date", "dealnum", "vstock", "year", "make",
             "model", "nu", "front_gross_profit", "back_gross_profit",
             "total_gross_profit", "cash_price", "pl", "sale_type",
             "salesman", "salesmanager", "fimanager")
KDARaw <- rename_at(KDARaw, o_names, ~ n_names)
########################################################################## add new rows

#########################################################################

#remove parenthesis and change parse
pear <- function(x) {
  x <- gsub("[()\\s,]", "", x)
  x <- as.numeric(x)
}
#clean all and make numeric
KDARaw <- mutate(KDARaw, across(c(front_gross_profit,
                          back_gross_profit,
                          total_gross_profit,
                          cash_price), 
                          pear))
#set date
KDARaw$date <- as.Date(KDARaw$date, format = "%m/%d/%Y")

# setting model year
#highest possible model year
# assumes no cars older than 100
max_year <- as.numeric(year(Sys.Date())) + 1
max_year <- as.numeric(substr(max_year, nchar(max_year[1])-1, nchar(max_year)))
KDARaw <- KDARaw %>%
  mutate(year = as.numeric(
    ifelse(str_length(year) == 1, str_c("200", year), 
                       ifelse(str_length(year) == 2 & year > max_year, str_c("19", year),
                              str_c("20", year))))
  )
#script specs
min_date <- min(KDARaw$date) - 365 # lowest obervable date
max_date <- max(KDARaw$date) + 31
stop_date <- as.Date("2020-03-26") # pre covid
  
#check classes
classcheck <- class(KDARaw$date) == "Date" & class(KDARaw$front_gross_profit) == "numeric"

#order by date
KDARaw <- KDARaw %>%
  arrange(date)

#copy df
KDAt <- KDARaw
########### plots + summaries have been moved ##############################################

#Roll up by day and by day per sale
#lots of missing days
#daily sums
day_sum <- group_by(KDAt, date) %>%
  mutate(fgp = sum(front_gross_profit, na.rm = T),
         tgp = sum(total_gross_profit, na.rm = T),
         cp = sum(cash_price, na.rm = T),
         n = length(nu)) %>%
  ungroup() %>%
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

#1727 days, but there should be 1782 ######

day_partial <- full_join(day_sum, day_avg, by = "date")

#Add the missing days

time_seq <- tibble(date = seq.Date(from = min(KDARaw$date), 
                                to = stop_date, by = 'day')) #should be current date eventually

day <- left_join(time_seq, day_partial, by = "date") %>%
  dplyr::select(date, n, tgp_a, cp_a)

## feature selection step##################################################
#corrgram(day)

#Imputation first:: Unit multiple imputation for 55 missing days
#using PMM
imp <- mice(data = day, print = F)
day_1_c <- complete(imp)

##### check
missingcheck <- sum(is.na(day_1_c)) == 0L
#create lags for day
# i'm going to lead y as opposed to lagging x
lead_1 <- 30 # 1 month
lead_2 <- 60 # 2 months
lead_3 <- 90 # 3 months
lead_6 <- 180 # 6 months
lead_12 <- 360 # 12 months

# add first 6 months
day_1_c <- left_join(
  tibble(date = seq.Date(from = min_date, 
                                     to = as.Date("2020-11-16"), by = 'day')),
  day_1_c, by = "date")

#completed imputation on __ values of __

###################### make leads #####################################
day_lead <- day_1_c %>%
  mutate(n_l1 = lead(n, lead_1),
         tgp_a_l1 = lead(tgp_a, lead_1), # help here
         cp_a_l1 = lead(cp_a, lead_1),
         
         n_l2 =  lead(n, lead_2),
         tgp_a_l2 = lead(tgp_a, lead_2),
         cp_a_l2 = lead(cp_a, lead_2),
         
         n_l3 = lead(n, lead_3),
         tgp_a_l3 = lead(tgp_a, lead_3),
         cp_a_l3 = lead(cp_a, lead_3),
         
         n_l6 = lead(n, lead_6),
         tgp_a_l6 = lead(tgp_a, lead_6),
         cp_a_l6 = lead(cp_a, lead_6),
         
         n_l12 = lead(n, lead_12),
         tgp_a_l12 = lead(tgp_a, lead_12),
         cp_a_l12 = lead(tgp_a, lead_12))

######################## now by month ###################################

#we will use daily averages and then average over the month 
month_sum <- group_by(KDAt, date = floor_date(date, unit = "month")) %>%
  mutate(fgp = sum(front_gross_profit, na.rm = T),
         tgp = sum(total_gross_profit, na.rm = T),
         cp = sum(cash_price, na.rm = T),
         n = n()) %>%
  ungroup() %>%
  summarise(date, fgp, tgp, cp, n) %>%
  distinct()

#daily average per sale
month_avg <- group_by(KDAt, date = floor_date(date, unit = "month")) %>%
  mutate(fgp_a = sum(front_gross_profit, na.rm = T)/n(),
         tgp_a = sum(total_gross_profit, na.rm = T)/n(),
         cp_a = sum(cash_price, na.rm = T)/n()) %>%
  ungroup() %>%
  summarise(date, fgp_a, tgp_a, cp_a) %>%
  distinct()

month_partial <- left_join(month_sum, month_avg, by = "date")
#### filter and select vars ####
month <- filter(month_partial, date < stop_date) %>% ##### change date in future v.s
  dplyr::select(date, n, tgp_a, cp_a) %>%
  arrange(date)

######################## variable selection ###############################
#corrgram(month)
# lead time in months now
lead_1 <- 1
lead_2 <- 2
lead_3 <- 3
lead_6 <- 6
lead_12 <- 12

month_lead <- month %>%
  right_join(
    tibble(date = floor_date(
      seq.Date(from = min_date, 
               to = stop_date, by = 'month'), unit = "month")), 
    by = "date") %>%
  mutate(n_l1 = lead(n, lead_1),
         tgp_a_l1 = lead(tgp_a, lead_1),
         cp_a_l1 = lead(cp_a, lead_1),
         
         n_l2 =  lead(n, lead_2),
         tgp_a_l2 = lead(tgp_a, lead_2),
         cp_a_l2 = lead(cp_a, lead_2),
         
         n_l3 = lead(n, lead_3),
         tgp_a_l3 = lead(tgp_a, lead_3),
         cp_a_l3 = lead(cp_a, lead_3),
         
         n_l6 = lead(n, lead_6),
         tgp_a_l6 = lead(tgp_a, lead_6),
         cp_a_l6 = lead(cp_a, lead_6),
         
         n_l12 = lead(n, lead_12),
         tgp_a_l12 = lead(tgp_a, lead_12),
         cp_a_l12 = lead(cp_a, lead_12)) %>%
  arrange(date)

######## make blank df to read into ########################################
#Fix blanks

blank_d <- dplyr::select(day_lead, date)  ### refer to raw df dates
blank_m <- dplyr::select(month_lead, date)