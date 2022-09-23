# this script compiles all csv data, administers a feature correlation cutoff cor_max 
# and filters features what will allow us to see 3 months into the future

# set correlation threshold
cor_max <- 0.15


#-------------------------------------------------------------------------------
# Home sales
# Consumer confidence index
# Interest Rates
# appointments
# Total vehicle sales retail SAAR (check between)
# SAAR in washington, King/Snohomish, cross-sell
# Google "car" searches

# Natural Rate of unemployment (short-term)

# work in python to download online data

setwd("~/LocalRStudio/LJ_Leading_Indicators/")

source("Transform.R", echo = FALSE)

library(Quandl)
library(dplyr)
library(tidyr)
library(readr)


# From Quandl, monthly observations don't come on the 1st
# Lag months and then filter to interval of nrow(month)

# read in month
month_pre <- read_csv("data/out/month_pre.csv")
month_post <- read_csv("data/out/month_post.csv")

#===============================================================================
# set search date boundaries
search_bottom <- min(month_pre$date) - years(1) # from month
search_top <- ceiling_date(max(month_post$date), unit = "month") - 1

paste("Searching between", search_bottom, "and", search_top)


lead_bottom <- search_top - years(1)
lead_top <- search_top # 3 months ahead!?!?!?

paste("Searching between", lead_bottom, "and", lead_top)


# write out
write_csv(tibble(search_bottom = search_bottom,
                 search_top = search_top,
                 lead_bottom = lead_bottom,
                 lead_top = lead_top), "keys/bounds.csv")

# blank df for join
blank_m <- tibble(date = seq.Date(from = search_bottom, to = search_top, by = "month"))

write_csv(blank_m, "keys/blank_m.csv")

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