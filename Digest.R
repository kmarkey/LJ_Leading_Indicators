# this script compiles all csv data, administers a feature correlation cutoff cor_max 
# and filters features what will allow us to see 3 months into the future


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

# From Quandl, monthly observations don't come on the 1st
# Lag months and then filter to interval of nrow(month)

# read in month?
month <- read_csv(paste0("./data/out/", monthfile))
#===============================================================================
# set search date boundaries

search_bottom <- min(month$date) - years(1) # from month
search_top <- ceiling_date(max(month$date), unit = "month") - 1

log_info("Searching for training feature data between {search_bottom} and {search_top}")

lead_bottom <- search_top - years(1)
lead_top <- search_top # 3 months ahead

log_info("Searching for forecast feature data between {lead_bottom} and {lead_top}")

log_trace("Saving search bounds and blank join frame")

# write out
boundlist <- tibble(search_bottom = search_bottom,
                 search_top = search_top,
                 lead_bottom = lead_bottom,
                 lead_top = lead_top) 

boundlist
write_csv(boundlist, "./keys/bounds.csv")

# blank df for join, and join
blank_m <- tibble(date = seq.Date(from = as.Date(search_bottom), to = search_top, by = "month"))

log_info("Selecting {targetvar} from {monthfile}")

# replace all NAs with 0s
mylist <- list()

for (avar in targetvar) {
  mylist[[avar]] = 0
}

mrow <- nrow(month)
mmissing <- sum(is.na(month))

if (monthfile == "month_post.csv") {
  min_date <- covid_cutoff + 1
}

month <- right_join(month, tibble(date = seq.Date(from = as.Date(min_date), to = search_top, by = "month"))) %>%
  arrange(desc(date)) %>%
  dplyr::select(date, all_of(targetvar)) %>%
  tidyr::replace_na(mylist)


log_info("Added {nrow(month) - mrow} months and replaced {sum(nrow(month) - mrow, is.na(month))} value with 0")

write_csv(blank_m, "./keys/blank_m.csv")


# #################### explore ideas #############################################
# library(corrplot)
# 
# corrplot(complete_cor, method = "color")
# corrplot(cor(features), method = "color")
# 
# complete_dirty %>%
#   dplyr::select(ends_with("_raw"), n, date) %>%
#   pivot_longer(cols = c(-n, -date), names_to = "tick", values_to = "value") %>%
#   ggplot() + geom_line(aes(x = date, y = n), color = "blue") +
#   geom_line(aes(x = date, y = value, group = tick, color = tick), alpha = 0.4) +
#   guides(color = "none") +
#   theme_minimal()
# 
# ggplot(complete_dirty) + geom_line(aes(x = date, y = n)) + 
#   geom_line(aes(x = date, y = ARM5_raw, color = "var"))