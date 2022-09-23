
quandl_get <- function(quandl_code, x, prefix, lower_bound, upper_bound) {
  df <- Quandl(code = quandl_code, collapse = 'monthly', 
               start_date = lower_bound, end_date = upper_bound) %>%
    dplyr::summarise(date = floor_date(Date, unit = "month"), {{prefix}} := .data[[x]]) %>%
    
  return(df)
}

library(Quandl)
library(dplyr)
library(tidyr)
library(readr)


# read in keys
keys <- read_delim("keys/keys.txt", delim = ",", trim_ws = TRUE)
Quandl.api_key(as.character(keys$key[4]))

setwd("~/LocalRStudio/LJ_Leading_Indicators/")


#=============================select quandl series==============================
# OPEC crude oil
oil <- quandl_get("OPEC/ORB", x = "Value", prefix = "oil", search_bottom, search_top)

# E-mini Natural Gas Futures, Continuous Contract #1 (QG1) (Front Month)
NGF1 <- quandl_get("CHRIS/CME_QG1", x = "Settle", prefix = "ngf1", search_bottom, search_top)

# E-mini Natural Gas Futures, Continuous Contract #2 (QG2)
NGF2 <- quandl_get("CHRIS/CME_QG2", x = "Volume", prefix = "ngf2", search_bottom, search_top)

# 90 Day Bank Accepted Bills Futures, Continuous Contract #1 (IR1) (Front Month)
IR1 <- quandl_get("CHRIS/ASX_IR1", x = "Previous Settlement", prefix = "bf90", search_bottom, search_top)

# House Price Indices - Seattle-Tacoma-Bellevue WA
HPISTB <- quandl_get("FMAC/HPI_42660", x = "SA Value", prefix = "lhpi", search_bottom, search_top)

# HPI - Washington State
HPIWA <- quandl_get("FMAC/HPI_WA", x = "SA Value", prefix = "shpi", search_bottom, search_top)

# 15-Year Fixed Rate Mortgage Average in the United States
FRM15 <- quandl_get("FMAC/15US", x = "Value", prefix = "mfrm", search_bottom, search_top)

# 30-Year Fixed Rate Mortgage Average in the United States
FRM30 <- quandl_get("FMAC/30US", x = "Value", prefix = "lfrm", search_bottom, search_top)

# 5/1-Year Adjustable Rate Mortgage Average in the United States
ARM5 <- quandl_get("FMAC/5US", x = "Value", prefix = "sfrm", search_bottom, search_top)

blank_m <- read_csv("keys/blank_m.csv")

quandl_data <- # maybe expand all after join?
  left_join(oil, NGF1, by = "date") %>%
  left_join(NGF2, by = "date") %>%
  
  left_join(IR1, by = "date") %>%
  left_join(HPISTB, by = "date") %>%
  left_join(HPIWA, by = "date") %>%
  left_join(FRM15, by = "date") %>%
  left_join(FRM30, by = "date") %>%
  left_join(ARM5, by = "date")

write_csv(quandl_data, "data/in/quandl.csv")
