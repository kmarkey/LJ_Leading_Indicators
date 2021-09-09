#Running Questions bar
# What do these variables actually mean?
# Which ones would be best to track? Which is the best indicator of overall business performance?
# How can we ingest lots more data? Can we get local data?

# COnditions
# Used all good data, no collinearity
# Summed up values per day
# Took a ts() for freq = 365, observing a yearly trend
# Tested against a quarter and 2-quarter lead
# More parameters than experimental variables--good or bad?

library(tidyverse)
library(mice)
library(ggridges)
library(lubridate)

library(Quandl)
library(Hmisc)
library(corrgram)

####################################################################### warnings suppressed
options(warn = -1)
#######################################################################
#set dir
setwd("~/LocalRStudio/LJ_Leading_Indicators")

KDARaw <- read_csv("data/Keaton Data Analysis Project-2016-2020.csv",
                   na = c("", "-", "--", "---", "	 -   ", " -   ", " ", "  "), 
                   skip = 1, trim_ws = TRUE, col_names = TRUE)

colnames(KDARaw) <- (c("Date", "DealNum", "VStock", "Year", "Make",
                       "Model", "NU", "Front_Gross_Profit", "Back_Gross_Profit",
                       "Total_Gross_Profit", "Cash_Price", "PL", "Sale_Type",
                       "Salesman", "Salesmanager", "FIManager"))

#remove parenthesis and change parse
pear <- function(x){
  x <- gsub("[()]", "", x)
  x <- gsub(" ", "", x)
  x <- gsub(",", "", x)
  x <- as.numeric(x)
}

#use across
KDARaw <- mutate(KDARaw, across(c(Front_Gross_Profit,
                          Back_Gross_Profit,
                          Total_Gross_Profit,
                          Cash_Price), pear))

#set date
KDARaw$Date <- as.Date(KDARaw$Date, format = "%m/%d/%Y")

#check date
class(KDARaw$Date)
class(KDARaw$Front_Gross_Profit)

KDARaw <- arrange(KDARaw, Date)

summary(KDARaw)
str(KDARaw)

head(KDARaw)
tail(KDARaw)

#copy df
KDAt <- KDARaw

#3058 omitted values from back_gross_profit
#205 from front
#38  from total
#251 from cash price

#####

#Some quick EDA

######

#quick plots
plot(KDAt$Date,KDARaw$Front_Gross_Profit)
plot(KDAt$Date,KDARaw$Back_Gross_Profit)
plot(KDAt$Date,KDARaw$Total_Gross_Profit)
plot(KDAt$Date,KDARaw$Cash_Price)

###########
#Some trend exploration for Make
unique(KDAt$Make)
ggplot(KDAt, aes(Make)) + theme(axis.text = element_text(angle = 90)) + geom_bar()
ggplot(KDAt, aes(x = Make, y = Total_Gross_Profit)) + geom_boxplot() + 
  theme(axis.text = element_text(angle = 90))

#Nwow filter out Chevy Mazda and Kia
filter(KDAt, Make == c("CHEV", "MAZD", "KIA")) %>%
         ggplot() + 
  geom_smooth(aes(x = Date, y = Total_Gross_Profit, color = Make)) + theme_classic()

#New/Used
ggplot() + geom_smooth(data = filter(KDAt, NU == c("USED", "NEW")), 
                       aes(x = Date, y = Total_Gross_Profit, color = NU)) +
         geom_point(data = filter(KDAt, NU == "S"), aes(Date, Total_Gross_Profit, color = NU)) +  
  theme_classic()


# To roll up by day, we'll just omit missing values: shouldn't be a big deal for 
#all but Back_Gross_Profit --which we will not use cause it'll be hard to estimate
#such a large chunk of data (more than %15)

#Roll up by day and by day per sale
#lots of missing days
#daily sums
by_day <- group_by(KDAt, Date) %>%
  mutate(date = Date,
         fgp = sum(Front_Gross_Profit, na.rm = T),
         tgp = sum(Total_Gross_Profit, na.rm = T),
         cp = sum(Cash_Price, na.rm = T),
         n = length(NU)) %>%
  ungroup() %>%
  summarise(date, fgp, tgp, cp, n) %>%
  distinct()

#daily average per sale
bd_by_sale <- group_by(KDAt,Date) %>%
  mutate(date = Date,
         fgp_a = sum(Front_Gross_Profit)/length(NU),
         tgp_a = sum(Total_Gross_Profit)/length(NU),
         cp_a = sum(Cash_Price)/length(NU)) %>%
  ungroup() %>%
  summarise(date, fgp_a, tgp_a, cp_a) %>%
  distinct()

#1727 days, but there should be 1782

rogue <- full_join(by_day, bd_by_sale)

#Add the missing days
time_seq <- seq.Date(from = as.Date("2016-01-01"), 
                   to = as.Date("2020-11-16"), by = 'day')

blank <- as.data.frame(time_seq)
colnames(blank) <- c("date")

Day <- left_join(blank, rogue)

#corrgrams of all metrics
corrgram(select(Day, -date), order = TRUE, lower.panel = panel.shade, upper.panel = panel.pie, 
         text.panel = panel.txt, main = "'Daily' Corrgram")

#we want series with low correlation for our feature selection

# we will use cp, tgp, cp_a, tgp_a, fgp_a, so 5

Day <- select(Day, date, cp, cp_a, fgp_a, tgp, tgp_a)

#**Are the NA's randomly distributed?**

#### ridgeline time
nas <- pivot_longer(Day, cols = cp:tgp_a, names_to = c("names")) %>%
  filter(is.na(value)) #long df of all NA values for each name
nas %>%
  ggplot(aes(x = date, y = as.factor(names), fill = names)) +
    ggridges::geom_density_ridges(stat = "binline", bins = 52, scale = 1) + # about 52 months
  theme_classic() +
  theme(legend.position = "none") +
  labs(y = "variable name", title = "Distribution of NA's")

#The whole month of April 2020 is gone, so we cant really do anything with it
#2020-03-26 : 2020-04-30
# we will impute without these values for now ###
Day_1 <- filter(Day, date < "2020-03-26")

#Imputation first:: Unit multiple imputation for 55 missing days
#using PMM
imp <- mice(data = Day_1, print = F)
Day_1_c <- complete(imp)


#####??
which(is.na(Day_1_c))

lead_1 <- 90
lead_2 <- 180
############### back to Day ##################################################

#create leads
Day <- Day_1_c

# and get trends
#function with freq = 365 for  yearly pattern
trend_fun = function(raw) {
  decompose(ts(raw, frequency = 365))$trend
}
# go across
Day_t <- mutate(Day, across(-date, trend_fun))

###################### not the best strat #####################################
Day_t <- mutate(Day_t, cp_lead = lead(cp, lead_1),
              cp_a_lead = lead(cp_a, lead_1), # help here
              fgp_a_lead = lead(fgp_a, lead_1),
              tgp_lead = lead(tgp, lead_1),
              tgp_a_lead = lead(tgp_a, lead_1),
              
              cp_lead_6 = lead(cp, lead_2),
              cp_a_lead_6 = lead(cp_a, lead_2),
              fgp_a_lead_6 = lead(fgp_a, lead_2),
              tgp_lead_6 = lead(tgp, lead_2),
              tgp_a_lead_6 = lead(tgp_a, lead_2))

#Now we get trends

#did it work
ggplot(Day_t) + geom_line(aes(x = date, y = fgp_a)) +
  geom_line(aes(x = date, y = fgp_a_lead))

# remove extra rows at bottom
Day_t <- filter(Day_t, !is.na(cp) | !is.na(cp_lead_6))

#and by month
#we will use daily averages and then average over the month
Month <- group_by(KDAt, date = floor_date(Date, unit = "month")) %>%
  mutate(cp = sum(Cash_Price, na.rm = T),
         cp_a = mean(Cash_Price, na.rm = T),
         fgp_a = mean(Front_Gross_Profit, na.rm = T),
         tgp = sum(Total_Gross_Profit, na.rm = T),
         tgp_a = mean(Total_Gross_Profit, na.rm = T)) %>%
  ungroup() %>%
  summarise(date, cp, cp_a, fgp_a, tgp, tgp_a) %>%
  distinct()

# lead time in months now
lead_1 <- 3
lead_2 <- 6

#Now we get trends

#function with freq = 12 for  yearly pattern
trend_fun = function(raw) {
  decompose(ts(raw, frequency = 12))$trend
}
# go across
Month_t <- mutate(Month, across(-date, trend_fun))

# add leads
Month_t <- mutate(Month_t, cp_lead = lead(cp, lead_1),
                cp_a_lead = lead(cp_a, lead_1), # help here
                fgp_a_lead = lead(fgp_a, lead_1),
                tgp_lead = lead(tgp, lead_1),
                tgp_a_lead = lead(tgp_a, lead_1),
                
                cp_lead_6 = lead(cp, lead_2),
                cp_a_lead_6 = lead(cp_a, lead_2), # help here
                fgp_a_lead_6 = lead(fgp_a, lead_2),
                tgp_lead_6 = lead(tgp, lead_2),
                tgp_a_lead_6 = lead(tgp_a, lead_2))

#did it work
ggplot(Month_t) + geom_line(aes(x = date, y = fgp_a)) +
  geom_line(aes(x = date, y = fgp_a_lead))

# remove empty rows at the bottom
Month_t <- filter(Month_t, !is.na(cp) | !is.na(cp_lead_6))

#Fix blanks
blank_d <- select(Day_t, as.Date(date))
blank_m <- select(Month_t, date)

#reformat non-leads for plotting
daytplot <- select(Day_t, date:tgp_a) %>%
  pivot_longer(cols = cp:tgp_a, names_to = "metric", values_to = "value") %>%
  group_by(metric) %>%
  mutate(scaled = value/max(value, na.rm = T)) %>%
  filter(!is.na(scaled))

dcolors <- c("#E63946", "#ffb703", "#A8DBDC", "#457B9D", "#1D3557")

#normalized trends
daytplot %>%
  ggplot() +
  geom_line(aes(x = date, y = scaled, color = metric), size = 1.5) +
  geom_text(data = filter(daytplot, date == "2019-09-25"), 
            aes(label = c("cash price", "average cash price", "average front gross", 
                          "total gross profit", "average total gross"), 
                x = date, y = scaled), nudge_x = 50, hjust = -.01,  size = 3.5, angle = -50) +
  scale_x_date(limits = as.Date(c("2016-07-01", "2020-03-01"))) +
  theme_light() + theme(legend.position = "none", text = element_text(family = "sans")) + scale_color_manual(values = dcolors) +
  labs(x = "Date", y = "Value", title = "Trend Plot for 5 Important Business Metrics", 
       subtitle = "Using max scaling and yearly frequency of time-series data") +
  geom_segment(data = filter(daytplot, date == "2019-09-25"), 
               aes(x = date, xend = date + 30, y = scaled, yend = scaled, color = metric), 
               size = 1.5)


# wowza

longiplot <- select(Day_t, c(date, tgp_a, tgp_a_lead, tgp_a_lead_6)) %>%
  pivot_longer(cols = tgp_a:tgp_a_lead_6, names_to = "metric", values_to = "value") %>%
  group_by(metric) %>%
  mutate(scaled = value/max(value, na.rm = T)) %>%
  filter(!is.na(scaled))

longiplot %>%
  ggplot() +
  geom_line(aes(x = date, y = scaled, color = metric), size = 1.5) +
  geom_text(data = filter(daytplot, date == "2016-01-01"), 
            aes(label = c("tgp 6-month lead", "tgp 3-month lead", "tgp real-time"),
            x = as.Date(c("2016-01-01", "2016-04-01", "2016-07-01")), y = 0.85), hjust = -.2,  size = 3.5, angle = 45) +
  scale_x_date(limits = as.Date(c("2016-01-01", "2020-03-01"))) +
  theme_light() + theme(legend.position = "none") + scale_color_manual(values = dcolors[1:3]) +
  labs(x = "Date", y = "Value", title = "Trend Plot for Total Gross Profit", 
       subtitle = "Max scaled and led by 3 and 6 months")

# one more corrgram of our metrics
corrgram(Day_t, upper.panel = panel.pie)


#Lets get some data: from 2016-01-01 to 2020-03-25
#Start Very Broad
#QUANDL?

### function dev
#  we want to use day and month

  
  #ggplot(Kib.f) + geom_line(
  #                     aes(x = date, y = x/max(x, na.rm = T), color = "y")) +
  #  geom_line(aes(x = date, y = cp.a/max(cp.a, na.rm = T), color = "cp.a")) +  ylab("Value") +
  #  ggtitle(names(data[y]), "vs. fgp.lead")
# More data
#Analysis.R
