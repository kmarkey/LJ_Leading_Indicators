
quandl_get <- function(quandl_code, x, prefix, lower_bound, upper_bound) {
  df <- Quandl(code = quandl_code, collapse = 'monthly', 
               start_date = lower_bound, end_date = upper_bound) %>%
    dplyr::summarise(date = floor_date(Date, unit = "month"), {{prefix}} := .data[[x]]) %>%
    
  return(df)
}

library(Quandl)
library(lubridate)
library(dplyr)
library(tidyr)
library(readr)
library(logger)
library(here)

here()

# read in keys
log_trace("Remembering where you left the API keys")

keys <- read_delim("keys/keys.txt", delim = ",", trim_ws = TRUE)
Quandl.api_key(as.character(keys$key[4]))

blank_m <- read_csv("keys/blank_m.csv")
#============================= read date bounds ================================

bounds <- read_csv("./keys/bounds.csv")
#========================= is current file up to date? =========================

if (file.exists("./data/in/quandl.csv")) {
  exist <- read_csv("./data/in/quandl.csv")
  log_trace("Checking existing Quandl data")
}

if (nrow(exist) == nrow(blank_m) && 
    min(exist$date) == min(blank_m$date) && 
    max(exist$date) == max(blank_m$date)) {
  log_info("Using existing Quandl data")
} else {
#=============================select quandl series==============================

  # OPEC crude oil
  log_trace("Reading OPEC crude oil")
  oil <- quandl_get("OPEC/ORB", x = "Value", prefix = "oil", bounds$search_bottom, bounds$search_top)
  
  # E-mini Natural Gas Futures, Continuous Contract #1 (QG1) (Front Month)
  log_trace("Reading E-mini Natural Gas Futures, Continuous Contract #1 (QG1) (Front Month)")
  NGF1 <- quandl_get("CHRIS/CME_QG1", x = "Settle", prefix = "ngf1", bounds$search_bottom, bounds$search_top)
  
  # E-mini Natural Gas Futures, Continuous Contract #2 (QG2)
  log_trace("Reading E-mini Natural Gas Futures, Continuous Contract #2 (QG2) Volume")
  NGF2 <- quandl_get("CHRIS/CME_QG2", x = "Volume", prefix = "ngf2", bounds$search_bottom, bounds$search_top)
  
  # 90 Day Bank Accepted Bills Futures, Continuous Contract #1 (IR1) (Front Month)
  log_trace("Reading 90 Day Bank Accepted Bills Futures, Continuous Contract #1 (IR1) (Front Month)")
  IR1 <- quandl_get("CHRIS/ASX_IR1", x = "Previous Settlement", prefix = "bf90", bounds$search_bottom, bounds$search_top)
  
  # House Price Indices - Seattle-Tacoma-Bellevue WA
  log_trace("Reading House Price Indices - Seattle-Tacoma-Bellevue WA")
  HPISTB <- quandl_get("FMAC/HPI_42660", x = "SA Value", prefix = "lhpi", bounds$search_bottom, bounds$search_top)
  
  # HPI - Washington State
  log_trace("Reading HPI - Washinton State")
  HPIWA <- quandl_get("FMAC/HPI_WA", x = "SA Value", prefix = "shpi", bounds$search_bottom, bounds$search_top)
  
  # 15-Year Fixed Rate Mortgage Average in the United States
  log_trace("Reading 15-Year FRM Average in the United States")
  FRM15 <- quandl_get("FMAC/15US", x = "Value", prefix = "mfrm", bounds$search_bottom, bounds$search_top)
  
  # 30-Year Fixed Rate Mortgage Average in the United States
  log_trace("Reading 30-Year FRM Average in the United States")
  FRM30 <- quandl_get("FMAC/30US", x = "Value", prefix = "lfrm", bounds$search_bottom, bounds$search_top)
  
  # 5/1-Year Adjustable Rate Mortgage Average in the United States
  log_trace("Reading 5/1-Year Adjustable Rate Mortgage Average in the United States")
  ARM5 <- quandl_get("FMAC/5US", x = "Value", prefix = "sfrm", bounds$search_bottom, bounds$search_top)
  
  log_info("Smashing all Quandl together")
  
  quandl_data <-
    left_join(oil, NGF1, by = "date") %>%
    left_join(NGF2, by = "date") %>%
    left_join(IR1, by = "date") %>%
    left_join(HPISTB, by = "date") %>%
    left_join(HPIWA, by = "date") %>%
    left_join(FRM15, by = "date") %>%
    left_join(FRM30, by = "date") %>%
    left_join(ARM5, by = "date")
  
  log_info("Quandl.csv saved!")

  write_csv(quandl_data, "./data/in/quandl.csv")

}

# save feature descriptions too?
