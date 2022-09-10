# this script compiles all csv data and administers a feature correlation cutoff cor_max 
# and filters features what will allow us to see 3  months into the future

# correlation function

exam <- function(data, threshold = 0.25, interval = "month") {

  if (interval == 'month'){
    data <- left_join(month, data, by = "date") %>%
      dplyr::select(-date, -tgp_a, -cp_a)
    #correlation matrix
    rac <- as.data.frame(
      cor(data, use = "pairwise.complete.obs"))
    out <- rac %>%
      dplyr::select(n) %>%
      filter(n != 1) %>%
      arrange(desc(abs(n)))
    pass <- filter(out, abs(n) >= threshold)
    print(pass)
    
  # for now print out all
  }
}


quandl_lag <- function(quandl_code, x, prefix, lower_bound, upper_bound, join_key) {
  df <- Quandl(code = quandl_code, collapse = 'monthly', 
               start_date = lower_bound, end_date = upper_bound) %>%
    dplyr::summarise(date = floor_date(Date, unit = "month"), {{prefix}} := .data[[x]]) %>%

    # lag snap
    right_join(join_key, by = "date") %>% # arranges high to low
    dplyr::mutate(across({{prefix}}, .fns = list(raw = ~.,
                                        lag1 = ~ lead(., 1), 
                                        lag2 = ~ lead(., 2),
                                        lag3 = ~ lead(., 3),
                                        lag6 = ~ lead(., 6),
                                        lag12 = ~ lead(., 12)),
                         .names = "{.col}_{.fn}"), 
                  .keep = "unused")
  return(df)
  # assign(paste({{name}}, "lgd", sep = "_"), result, envir = .GlobalEnv, inherits = FALSE)
}


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
library(tidyselect)
library(ggplot2)
library(tidyr)
library(readr)

Quandl.api_key("DLPMVwPNyH57sF6Z1iM4")

# From Quandl, monthly observations don't come on the 1st
# Lag months and then filter to interval of nrow(month)

# read in month
month <- read_csv("data/out/month.csv")

# create date bounaries
search_bottom <- min(month$date) - years(1) # from month
search_bottom
search_top <- ceiling_date(max(month$date), unit = "month") - 1
search_top


# set correlation threshold
cor_max <- 0.20

# blank df for join
blank_m <- tibble(date = seq.Date(from = search_bottom, to = search_top, by = "month"))

#=============================select quandl series==============================
# OPEC crude oil
oil <- quandl_lag("OPEC/ORB", x = "Value", prefix = "oil", search_bottom, search_top, blank_m)
exam(oil, cor_max)

# E-mini Natural Gas Futures, Continuous Contract #1 (QG1) (Front Month)
NGF1 <- quandl_lag("CHRIS/CME_QG1", x = "Settle", prefix = "ngf1", search_bottom, search_top, blank_m)
exam(NGF1, cor_max)

# E-mini Natural Gas Futures, Continuous Contract #2 (QG2)
NGF2 <- quandl_lag("CHRIS/CME_QG2", x = "Volume", prefix = "ngf2",search_bottom, search_top, blank_m)
exam(NGF2, cor_max)

# 90 Day Bank Accepted Bills Futures, Continuous Contract #1 (IR1) (Front Month)
IR1 <- quandl_lag("CHRIS/ASX_IR1", x = "Previous Settlement", prefix = "bf90", search_bottom, search_top, blank_m)
exam(IR1, cor_max)

# House Price Indices - Seattle-Tacoma-Bellevue WA
HPISTB <- quandl_lag("FMAC/HPI_42660", x = "SA Value", prefix = "lhpi", search_bottom, search_top, blank_m)
exam(HPISTB, cor_max)

# HPI - Washington State
HPIWA <- quandl_lag("FMAC/HPI_WA", x = "SA Value", prefix = "shpi", search_bottom, search_top, blank_m)
exam(HPIWA, cor_max)

# 15-Year Fixed Rate Mortgage Average in the United States
FRM15 <- quandl_lag("FMAC/15US", x = "Value", prefix = "mfrm", search_bottom, search_top, blank_m)
exam(FRM15, cor_max)

# 30-Year Fixed Rate Mortgage Average in the United States
FRM30 <- quandl_lag("FMAC/30US", x = "Value", prefix = "lfrm", search_bottom, search_top, blank_m)
exam(FRM30, cor_max)

# 5/1-Year Adjustable Rate Mortgage Average in the United States
ARM5 <- quandl_lag("FMAC/5US", x = "Value", prefix = "sfrm", search_bottom, search_top, blank_m)
exam(ARM5, cor_max)


#============================ Fred data and stocks from python =================
# stock_names <- str_extract(stock_list, "[A-Z]+")
# econ <- list.files(path = "data/in/stocks", full.names = TRUE) %>%
#   lapply(read_csv) %>%
#   bind_cols
#   right_join(blank_m, by = "date") %>% # arranges high to low
#   dplyr::mutate(across(is.numeric, .fns = list(raw = ~.,
#                                                lag1 = ~ lag(., 1), 
#                                                lag2 = ~ lag(., 2),
#                                                lag3 = ~ lag(., 3),
#                                                lag6 = ~ lag(., 6),
#                                                lag12 = ~ lag(., 12)),
#                        .names = "{.col}_{.fn}"), 
#                 .keep = "unused")
# 
# exam(econ)

fred <- read_csv("data/in/fred.csv")

fred <- fred %>%
  right_join(blank_m, by = "date") %>% # arranges high to low
  dplyr::mutate(across(is.numeric, .fns = list(raw = ~.,
                                               lag1 = ~ lag(., 1), 
                                               lag2 = ~ lag(., 2),
                                               lag3 = ~ lag(., 3),
                                               lag6 = ~ lag(., 6),
                                               lag12 = ~ lag(., 12)),
                       .names = "{.col}_{.fn}"), 
                .keep = "unused")

exam(fred, cor_max)

#============================== stocks =========================================
stock_list <- list.files(path = "data/in/stocks", full.names = TRUE)

GM <- read_csv("data/in/stocks/GM.csv") %>%
  rename(GM = close)
FB <- read_csv("data/in/stocks/F.csv") %>%
  rename(FB = close)
AN <- read_csv("data/in/stocks/AN.csv") %>%
  rename(AN = close)
TSLA <- read_csv("data/in/stocks/TSLA.csv") %>%
  rename(TSLA = close)

stocks <- blank_m %>%
  left_join(GM, by = "date") %>% 
  left_join(FB, by = "date") %>%
  left_join(AN, by = "date") %>%
  left_join(TSLA, by = "date") %>%# arranges high to low
  dplyr::mutate(across(is.numeric, .fns = list(raw = ~.,
                                               lag1 = ~ lag(., 1), 
                                               lag2 = ~ lag(., 2),
                                               lag3 = ~ lag(., 3),
                                               lag6 = ~ lag(., 6),
                                               lag12 = ~ lag(., 12)),
                       .names = "{.col}_{.fn}"), 
                .keep = "unused")

exam(stocks, cor_max)

#=============================== google trends =================================
trends <- read_csv("data/in/trends.csv")

trends <- blank_m %>%
  left_join(trends, by = "date") %>% # arranges high to low
  dplyr::mutate(across(is.numeric, .fns = list(raw = ~.,
                                               lag1 = ~ lag(., 1), 
                                               lag2 = ~ lag(., 2),
                                               lag3 = ~ lag(., 3),
                                               lag6 = ~ lag(., 6),
                                               lag12 = ~ lag(., 12)),
                       .names = "{.col}_{.fn}"), 
                .keep = "unused")

######## add appts here? #########



#=============================== joins =========================================

scaling <- function(x) { # normalization function
  return((x - min(x))/(max(x) - min(x)))
}

complete_dirty <- left_join(dplyr::select(month, date, n),  # combine all to 1 df
                      oil, by = "date") %>%
  left_join(NGF1, by = "date") %>%
  left_join(NGF2, by = "date") %>%
  
  left_join(IR1, by = "date") %>%
  left_join(HPISTB, by = "date") %>%
  left_join(HPIWA, by = "date") %>%
  left_join(FRM15, by = "date") %>%
  left_join(FRM30, by = "date") %>%
  left_join(ARM5, by = "date") %>%
  
  # econ
  left_join(fred, by = "date") %>%
  left_join(stocks, by = "date") %>%
  left_join(trends, by = "date") %>%
  
  # google results
  
  # add more later
  #######################################
  tibble::rowid_to_column("month") %>%
  dplyr::select(-date)
  # mutate(across(is.numeric, ~ scaling(.))) # apply scaling with sklearn

#============================ wide filter to cor ===============================
write_csv(complete_dirty, "data/out/complete.csv")

# change date to month key col
complete_cor <- complete_dirty %>%
  cor()

# select for co  >= 0.25
feature_dict <- complete_cor[complete_cor['n',] >= cor_max | complete_cor['n',] <= -cor_max, 'n']

# select features in features dict
features <- dplyr::select(complete_dirty, all_of(names(feature_dict))) %>%
  dplyr::select(-ends_with(c("_raw", "_lag1", "_lag2")))


#==================================== write out ================================
write_csv(features, "data/out/features.csv")

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