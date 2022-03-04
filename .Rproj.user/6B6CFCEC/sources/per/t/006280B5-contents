##### 
# correlation function
# to look at correlation for number of sales n
exam <- function(data, interval = "month") {

  if (interval == 'month'){
    data <- left_join(month, data, by = "date") %>%
      dplyr::select(-date, -tgp_a, -cp_a)
    #correlation matrix
    rac <- as.data.frame(
      cor(data, use = "pairwise.complete.obs"))
  }
  else(print("Invalid Date Format"))
  #for now just print it out
  rac %>%
    dplyr::select(n) %>%
    filter(n != 1) %>%
    arrange(desc(abs(n)))
  #Choose close variables and plot them with data
}
#takes df with date and makes 4 lagged new columns
past <- function(data, x = Value) {
  name <- deparse(substitute(data))
  df <- data %>%
    dplyr::select(date, x = {{x}})
  
  result <- tibble(date = head(df$date, nrow(month)),
                   lag12 = df$x[13:(nrow(month) + 12)], # lag 12 months
                   lag6 = df$x[7:(nrow(month) + 6)], # lag 6 months
                   lag3 = df$x[4:(nrow(month) + 3)], # 3months
                   lag2 = df$x[3:(nrow(month) + 2)], # 2 months
                   lag1 = df$x[2:(nrow(month) + 1)],
                   raw = head(df$x, nrow(month))) # 1 month lag
  #colnames(result) <- paste(name, colnames(result), sep = "_") # change names
  result <- dplyr::rename_with(result, ~ paste(name, .x, sep = "_"),
                               .cols = where(is.numeric))
  assign(paste(name, "lgd", sep = "_"), result, envir = .GlobalEnv, inherits = FALSE)
}
#Home sales
#Consumer confidence index
#Interest Rates
#appointments
#Total vehicle sales retail SAAR (check between)
#SAAR in washington, King/Snohomish, cross-sell

#Predict appointments set?

#Online searching data, website hits?

#Natural Rate of unemployment (short-term)

#work with python to ingest online data

setwd("~/LocalRStudio/LJ_Leading_Indicators")
source("Tranform.R", echo = FALSE)
library(Quandl)
library(ggplot2)
Quandl.api_key("DLPMVwPNyH57sF6Z1iM4")

#date numbers
# wehn reading in data, no guerantee that it will be observed on the 1st,
# so we need to lag it and capture an inverval of however long nrow(month) is
search_bottom <- floor_date(min_date - 30, unit = "month")
search_top <- floor_date(max_date, unit = "month")
#OPEC crude oil
oil <- Quandl(code = "OPEC/ORB", collapse = 'monthly', 
              start_date = search_bottom, end_date = search_top) %>%
  mutate(date = floor_date(Date, unit = "month")) %>%
  right_join(blank_m, by = "date") # arranges high to low
past(oil, Value)
exam(oil_lgd)

#E-mini Natural Gas Futures, Continuous Contract #1 (QG1) (Front Month)
NGF1 <- Quandl("CHRIS/CME_QG1", collapse = 'monthly', start_date = search_bottom, end_date = search_top) %>%
  mutate(date = floor_date(as.Date(Date), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(NGF1, Settle)
exam(NGF1_lgd)

#E-mini Natural Gas Futures, Continuous Contract #2 (QG2)
NGF2 <- Quandl("CHRIS/CME_QG2", collapse = 'monthly', start_date = search_bottom, end_date = search_top) %>%
  mutate(date = floor_date(as.Date(Date), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(NGF2, Volume)
exam(NGF2_lgd)

#90 Day Bank Accepted Bills Futures, Continuous Contract #1 (IR1) (Front Month)
IR1 <- Quandl("CHRIS/ASX_IR1", collapse = 'monthly', start_date = search_bottom, end_date = search_top) %>% 
  mutate(date = floor_date(as.Date(Date), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(IR1, `Previous Settlement`)
exam(IR1_lgd)

#House Price Indices - Seattle-Tacoma-Bellevue WA
HPISTB <- Quandl("FMAC/HPI_42660", collapse = 'monthly', start_date = search_bottom, end_date = search_top) %>% 
  mutate(date = floor_date(as.Date(Date), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(HPISTB, `SA Value`)
exam(HPISTB_lgd)

#HPI - Washington State
HPIWA <- Quandl("FMAC/HPI_WA", collapse = 'monthly', start_date = search_bottom, end_date = search_top) %>% 
  mutate(date = floor_date(as.Date(Date), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(HPIWA, `SA Value`)
exam(HPIWA_lgd)

#15-Year Fixed Rate Mortgage Average in the United States
FRM15 <- Quandl("FMAC/15US", collapse = 'monthly', start_date = search_bottom, end_date = search_top) %>% 
  mutate(date = floor_date(as.Date(Date), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(FRM15)
exam(FRM15_lgd)

#30-Year Fixed Rate Mortgage Average in the United States
FRM30 <- Quandl("FMAC/30US", collapse = 'monthly', start_date = search_bottom, end_date = search_top) %>% 
  mutate(date = floor_date(as.Date(Date), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(FRM30)
exam(FRM30_lgd)

#5/1-Year Adjustable Rate Mortgage Average in the United States
ARM5 <- Quandl("FMAC/5US", collapse = 'monthly', start_date = search_bottom, end_date = search_top) %>% 
  mutate(date = floor_date(as.Date(Date), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(ARM5)
exam(ARM5_lgd)

# Consumer Confidence Index full list https://data.oecd.org/leadind/consumer-confidence-index-cci.htm
CCI <- read_csv("data/ConsumerConfidenceUSA.csv") # fetch with python
CCI <- CCI %>%
  mutate(date = str_c(as.character(`TIME`), '-01')) %>%
  mutate(date = floor_date(as.Date(date, format = "%Y-%m-%d"), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(CCI)
exam(CCI_lgd)

# SAAR light vehicle sales https://fred.stlouisfed.org/series/ALTSALES
SAAR1 <- read_csv("data/ALTSALES.csv")
SAAR1 <- SAAR1 %>%
  mutate(date = floor_date(as.Date(DATE), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(SAAR1, ALTSALES)
exam(SAAR1_lgd)

# Total Vehicle Sales https://fred.stlouisfed.org/series/TOTALSA
SAAR2 <- read_csv("data/TOTALSA.csv") 
SAAR2 <- SAAR2 %>%
  mutate(date = floor_date(as.Date(DATE), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(SAAR2, TOTALSA)
exam(SAAR2_lgd)

#Light Trucks https://fred.stlouisfed.org/series/LTRUCKSA
SAAR3 <- read_csv("data/LTRUCKSA.csv") 
SAAR3 <- SAAR3 %>%
  mutate(date = floor_date(as.Date(DATE), unit = "month")) %>%
  right_join(blank_m, by = "date")
past(SAAR3, LTRUCKSA)
exam(SAAR3_lgd)

#################appts #######################################################

### combine all into df > train and test in python
#plus normalization

scaling <- function(x) {
  (x - min(x))/(max(x) - min(x))
}

complete <- left_join(month,
                      NGF1_lgd, by = "date") %>%
  left_join(NGF2_lgd, by = "date") %>%
  left_join(IR1_lgd, by = "date") %>%
  left_join(HPISTB_lgd, by = "date") %>%
  left_join(HPIWA_lgd, by = "date") %>%
  left_join(FRM15_lgd, by = "date") %>%
  left_join(FRM30_lgd, by = "date") %>%
  #add more later
  #######################################

  left_join(ARM5_lgd, by = "date") %>%
  
  mutate(across(is.numeric, ~(scaling(.) %>% as.vector)))

#write_csv(complete, "data/complete.csv")

features <- dplyr::select(complete, -ends_with("raw"))

#write_csv(features, "data/features.csv")