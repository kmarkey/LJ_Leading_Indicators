
#using other data
#Using exam funtion, Quandl package, and Day.t


#Home sales
#Consumer confidence index
#Interest Rates
#appointments
#Total vehicle sales retail SAAR (check between)
#SAAR in washington, King/Snohomish, cross-sell

#Predict appointments set?

#Online searching data, website hits?

#Natural Rate of unemployment (short-term)

#source("Tranform.R")
#Also, we'll just select a few indicators that we think are important to our model

Quandl.api_key("DLPMVwPNyH57sF6Z1iM4")
source("Tranform.R", echo = FALSE)  ##???

#explore a lil

#OPEC crude oil
oil <- Quandl(code = "OPEC/ORB", collapse = 'daily', 
              start_date = "2016-01-01", end_date = "2020-03-25", force_irregular = TRUE)
oil <- left_join(blank_d, oil, by =  c("date" = "Date"))
#cor
cor(Day_t$cp, oil$Value, use = "na.or.complete")

#GM data
GM <- read.csv("data/GM.csv")
GM$date <- as.Date(GM$Date)
GM <- left_join(blank_d, GM, by =  "date")
cor(Day_t$cp, GM$Adj.Close, use = "na.or.complete")
ggplot() + geom_line(data = Day_t, aes(date, fgp_a_lead/max(fgp_a_lead, na.rm = T))) + 
  geom_line(data = GM, aes(date, Adj.Close/max(Adj.Close, na.rm = T)))
print(a)

exam(data = GM, y = Adj.Close, time = "day")
#function {exam}

indicators_d <- data.frame(date = Day_t$date)
exam <- function(data, y, time = "day") {
  
  if (time == 'day'){
    input <- select(data, date, {{y}})
    data <- left_join(Day_t, input, by = "date") %>%
      select(-date)
    #correlation matrix
    rac <- as.data.frame(
      cor(data, use = "na.or.complete"))
    #output running table somehow
    
}
  else if (time == 'month'){
    input <- select(data, date, {{y}})
    data <- left_join(Month_t, input, by = "date") %>%
      select(-date)
    #correlation matrix
    rac <- as.data.frame(
      cor(data, use = "na.or.complete"))
    }
  else(print("Error Help AHHHHHHH"))
  
  
  #We only want last column of rac
  #start running table?
  #one for d and one for m
  #how am I going to combine them
  
  #for now just print it out
  arrange(rac, desc(abs({{y}}))) %>%
    select({{y}}) %>%
    filter({{y}} != 1)
  #Choose close variables and plot them with data
}

#E-mini Natural Gas Futures, Continuous Contract #1 (QG1) (Front Month)
Quandl("CHRIS/CME_QG1", collapse = 'daily', start_date = "2016-01-01", end_date = "2020-03-25") %>%
  mutate(date = as.Date(Date)) %>%
  exam(y = Settle, time = "day")

#E-mini Natural Gas Futures, Continuous Contract #2 (QG2)
Quandl("CHRIS/CME_QG2", collapse = 'daily', start_date="2016-01-01", end_date="2020-03-25") %>%
  mutate(date = as.Date(Date)) %>%
  exam(Settle, 'day')

#90 Day Bank Accepted Bills Futures, Continuous Contract #1 (IR1) (Front Month)
Quandl("CHRIS/ASX_IR1", collapse = 'daily', start_date="2016-01-01", end_date="2020-03-25") %>% 
  mutate(date = as.Date(Date)) %>%
  exam(`Previous Settlement`, 'day')

#House Price Indices - Seattle-Tacoma-Bellevue WA
Quandl("FMAC/HPI_42660", collapse = 'monthly', start_date = "2016-01-01", end_date = "2020-03-31") %>%
  mutate(date = floor_date(Date, unit = "month")) %>%
  exam(`NSA Value`, 'month')

#HPI - Washington State
Quandl("FMAC/HPI_WA", collapse = 'monthly', start_date = "2016-01-01", end_date = "2020-03-31") %>%
  mutate(date = floor_date(Date, unit = "month")) %>%
  exam(`NSA Value`, 'month')

#15-Year Fixed Rate Mortgage Average in the United States
Quandl("FMAC/15US", collapse = 'monthly', start_date = "2016-01-01", end_date = "2020-03-31") %>%
  mutate(date = floor_date(Date, unit = "month")) %>%
  exam(`Value`, 'month')

#30-Year Fixed Rate Mortgage Average in the United States
Quandl("FMAC/30US", collapse = 'monthly', start_date = "2016-01-01", end_date = "2020-03-31") %>%
  mutate(date = floor_date(Date, unit = "month")) %>%
  exam(`Value`, 'month')

#5/1-Year Adjustable Rate Mortgage Average in the United States
Quandl("FMAC/5US", collapse = 'monthly', start_date = "2016-01-01", end_date = "2020-03-31") %>%
  mutate(date = floor_date(Date, unit = "month")) %>%
  exam(`Value`, 'month')

# Consumer Confidence Index full list https://data.oecd.org/leadind/consumer-confidence-index-cci.htm
cci <- read_csv("data/ConsumerConfidenceUSA.csv")
cci %>%
  mutate(date = str_c(as.character(TIME), '-01')) %>%
  mutate(date = as.Date(date, format = "%Y-%m-%d")) %>%
  exam(`Value`, 'month')


# SAAR light vehicle sales https://fred.stlouisfed.org/series/ALTSALES
SAAR1 <- read_csv("data/ALTSALES.csv")
mutate(SAAR1, date = DATE) %>%
  exam(`ALTSALES`, 'month')

# Total Vehicle  Sales https://fred.stlouisfed.org/series/TOTALSA
SAAR2 <- read_csv("data/TOTALSA.csv") 
mutate(SAAR2, date = DATE) %>%
  exam(`TOTALSA`, 'month')

#Light Trucks https://fred.stlouisfed.org/series/LTRUCKSA
SAAR3 <- read_csv("data/LTRUCKSA.csv") 
mutate(SAAR3, date = DATE) %>%
  exam(`LTRUCKSA`, 'month')


# make them into a whole df
