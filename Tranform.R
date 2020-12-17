library(tidyverse)
library(mice)

KDARaw <- read.csv("C:/Users/keato/Dropbox/Shop Data/Keaton Data Analysis Project-2016-2020.csv", 
                   na.strings = c("", "-", "--", "---", "	 -   ", " -   ", " ", "  ", strip.white = TRUE))

colnames(KDARaw) <- (c("Date", "DealNum", "VStock", "Year", "Make",
                       "Model", "NU", "Front_Gross_Profit", "Back_Gross_Profit",
                       "Total_Gross_Profit", "Cash_Price", "PL", "Sale_Type",
                       "Salesman", "Salesmanager", "FIManager"))
#remove first row
KDARaw<-as.data.frame(KDARaw)

KDARaw<- KDARaw[-c(1),]

#remove parenthesis and change parse
pear<- function(x){
  x<- gsub("[()]", "", x)
  x<- gsub(" ", "", x)
  x<- as.numeric(gsub(",", "", x))
}
KDARaw$Front_Gross_Profit<-pear(KDARaw$Front_Gross_Profit)
KDARaw$Back_Gross_Profit<-pear(KDARaw$Back_Gross_Profit)
KDARaw$Total_Gross_Profit<- pear(KDARaw$Total_Gross_Profit)
KDARaw$Cash_Price<-pear(KDARaw$Cash_Price)

KDARaw$Date<-as.Date(KDARaw$Date, format = "%m/%d/%Y")
KDARaw$PL<-as.factor(KDARaw$PL)
KDARaw$NU<-as.factor(KDARaw$NU)

#check date
class(KDARaw$Date)
class(KDARaw$Front_Gross_Profit)

KDARaw<- arrange(KDARaw, Date)

summary(KDARaw)
str(KDARaw)

head(KDARaw)
tail(KDARaw)

#test df
KDAt<-KDARaw
#lets add some columns
KDAt<-left_join(KDAt, count(group_by(KDAt, Date)), by = "Date")

#But check for NAs
capture.output(
  sum(is.na(KDARaw$Back_Gross_Profit)),
  sum(is.na(KDARaw$Front_Gross_Profit)),
  sum(is.na(KDARaw$Total_Gross_Profit)),
  sum(is.na(KDARaw$Cash_Price)))
#3058 omitted values from back_gross-profit
#205 from front
#38  from total
#251 from cash price

#Logistic regression to tell if this affects results#
glm(is.na(Back_Gross_Profit) ~ Date, data = KDARaw, family = 'binomial')

ggplot(KDARaw,aes(x = Date, y = is.na(Back_Gross_Profit))) + geom_point()
ggplot(KDARaw,aes(x = Date, y = is.na(Cash_Price))) + geom_point()

#quick plots
plot(KDARaw$Date,KDARaw$Front_Gross_Profit)
plot(KDARaw$Date,KDARaw$Back_Gross_Profit)
plot(KDARaw$Date,KDARaw$Total_Gross_Profit)
plot(KDARaw$Date,KDARaw$Cash_Price)
###########
#Some trend exploration for Make
unique(KDAt$Make)
ggplot(KDAt, aes(Make)) + theme(axis.text = element_text(angle = 90)) + geom_bar()
ggplot(filter(KDAt, Make == c("CHEV", "MAZD", "KIA")), 
       aes(Date, Total_Gross_Profit/n)) +
  geom_smooth(aes(col = Make), se = T)
#Your average total gross for each car sale is increasing
ggplot(KDAt, aes(Make)) + theme(axis.text = element_text(angle = 90)) + geom_bar()
ggplot(filter(KDAt, Make == c("CHEV", "MAZD", "KIA")), 
       aes(Date, Back_Gross_Profit/n)) +
  geom_smooth(aes(col = Make), se = T)
###ggplot(filter(KDAt, Make == c("CHEV", "MAZD", "KIA")), 
###       aes(Date, Front_Gross_Profit/n)) +
###  geom_smooth(aes(col = Make), se = T) + facet_wrap(facets = KDA1$Make)


#New/Used
ggplot(filter(KDAt, NU == "USED"), aes(Date)) + geom_bar()
#after 2018
ggplot(filter(KDAt, Date >= "2018-01-01"), aes(Date)) + geom_bar(aes(col = NU))

ggplot(KDAt, aes(Date, Total_Gross_Profit/n)) + geom_smooth() + facet_wrap(facets = KDAt$NU)

#new df by day
#lots of missing days
Day<- as.data.frame(seq(as.Date("2016-01-01"), as.Date("2020-11-16"), by ="days"))
colnames(Day)<-c("Date")
temp<- group_by(KDAt, Date) %>%
  mutate(sum.fgp = sum(Front_Gross_Profit, na.rm = TRUE)) %>%
  summarise(sum.fgp, .groups = 'drop') %>%
  unique()
Day<-left_join(Day, count(group_by(KDAt, Date)), by = "Date")
Day<-left_join(Day, temp, by = "Date")
temp<- group_by(KDAt, Date) %>%
  mutate(sum.bgp= sum(Back_Gross_Profit, na.rm = TRUE)) %>%
  summarise(sum.bgp, .groups = 'drop') %>%
  unique()
Day<-left_join(Day, temp, by = "Date")
temp<- group_by(KDAt, Date) %>%
  mutate(sum.tgp = sum(Total_Gross_Profit, na.rm = TRUE)) %>%
  summarise(sum.tgp, .groups = 'drop') %>%
  unique()
Day<-left_join(Day, temp, by = "Date")
temp<- group_by(KDAt, Date) %>%
  mutate(sum.cp = sum(Cash_Price, na.rm = TRUE)) %>%
  summarise(sum.cp, .groups = 'drop') %>%
  unique()
Day<-left_join(Day, temp, by = "Date")

#1782 days, 55 NAs
summary(Day)

#Imputation with mice and just used pmm to impute
m<-'pmm'
imp <- mice(data = Day, m = 20, method = c("",m,m,m,m,m))
Day.full1<-complete(imp, 20)

#Fill with tidyr
Day.o<-na.omit(Day)
Day.full2<-fill(data = Day, dplyr::everything(), .direction = 'down')

#QUick plot

ggplot(Day.full1, aes(x = n)) + geom_bar()
ggplot(Day.full1, aes(x = Date, y = sum.fgp)) + geom_point()

#SUM _ by day raw with loess smooth
Day %>%
ggplot(aes(x = Date, y = .6*sum.tgp-600)) + geom_smooth(aes(color = "total gross"), se = FALSE) +
  geom_smooth(aes(x = Date, y = sum.bgp, color = "back gross"), se = FALSE) + 
  geom_smooth(aes(x = Date, y = .6*sum.fgp + 8700, color = "front gross"), se = FALSE) +
  geom_smooth(aes(x = Date, y = .15*(sum.cp-183000), color = "cash price"), se = FALSE) +
  geom_smooth(aes(x = Date, y = 1000*n+5000, color = "n sales"), se = FALSE) + ylab("")

#SUM _ by day imputed by pmm
Day.full1 %>%
ggplot(aes(x = Date, y = .6*sum.tgp-600)) + geom_smooth(aes(color = "total gross"), se = FALSE) +
  geom_smooth(aes(x = Date, y = sum.bgp, color = "back gross"), se = FALSE) + 
  geom_smooth(aes(x = Date, y = .6*sum.fgp + 8700, color = "front gross"), se = FALSE) +
  geom_smooth(aes(x = Date, y = .15*(sum.cp-183000), color = "cash price"), se = FALSE) +
  geom_smooth(aes(x = Date, y = 1000*n+5000, color = "n sales"), se = FALSE) + ylab("") + title("Sum by day")

#Average _ per sale by day normalized
Day.full1 %>%
ggplot(aes(x = Date, y = sum.tgp/n)) + stat_smooth(aes(color = "total gross"), se = FALSE) +
  stat_smooth(aes(x = Date, y = sum.bgp/n, color = "back gross"), se = FALSE) + 
  stat_smooth(aes(x = Date, y = sum.fgp/n, color = "front gross"), se = FALSE) +
  stat_smooth(aes(x = Date, y = .01*(sum.cp-160000), color = "cash price (norm)"), se = FALSE) +
  ylab("") + title("Avg. per Sale")

#Back Gross Profit and cash price looks interesting
#What is its relationship and relevance?

#We have observations starting in AUGUST 2019 to AUGUST 2020
#Lets start by year using sum TGP on Day
t.sum.fgp<-decompose(ts(Day.full1$sum.fgp, frequency = 365))
plot(t.sum.fgp)
t.sum.bgp<-decompose(ts(Day.full1$sum.bgp, frequency = 365))
plot(t.sum.bgp)
t.sum.tgp<-decompose(ts(Day.full1$sum.tgp, frequency = 365))
plot(t.sum.tgp)
t.sum.cp<-decompose(ts(Day.full1$sum.cp, frequency = 365))
plot(t.sum.cp)
t.n<-decompose(ts(Day.full1$n, frequency = 365))
plot(t.n)

#sum will be more useful and versatile
#looks good. now we need a dummy with dates for joining

time.seq<-seq.Date(from = as.Date("2016-01-01"), to = as.Date("2020-11-16"), by = 'day')
blank<-as.data.frame(time.seq)
colnames(blank)<-c("date")

#Clean first df
rogue<- cbind(as.data.frame(Day.full1$Date), as.data.frame(t.n$trend),
              as.data.frame(t.sum.fgp$trend),
              as.data.frame(t.sum.bgp$trend), as.data.frame(t.sum.tgp$trend), 
              as.data.frame(t.sum.cp$trend))
colnames(rogue)<-c("date", "n", "t.s.fgp", "t.s.bgp", "t.s.tgp", "t.s.cp")
rogue<-left_join(blank, rogue)

plot(rogue)

#Lets get some data: from 2016-01-01 to 2020-11-16
#Start Very Broad
#QUANDL?
library(Quandl)


#OPEC crude oil
oil<-Quandl(code = "OPEC/ORB", collapse = 'daily', 
            start_date="2016-01-01", end_date="2020-11-16", force_irregular = TRUE)
oil<-left_join(blank, oil, by =  c("date" = "Date"))

ggplot(rogue, aes(date, t.s.tgp, color = "LJ")) + geom_line() +
  geom_line(aes(oil$date-30, 100*oil$Value + 16000, color = "OPEC")) + geom_line()
cor(rogue$t.s.tgp, oil$Value, use = 'pairwise')

#GM data
GM <- read.csv("C:/Users/keato/Dropbox/Shop Data/GM.csv")
GM$Date<-as.Date(GM$Date)
GM <- left_join(blank, GM, by = c("date" = "Date"))
GM<-fill(data = GM, dplyr::everything(), .direction = 'down')


#again a normalized plot
ggplot(rogue, aes(date, t.s.tgp, color = "LJ tgp")) + geom_line() + 
  geom_line(aes(GM$date, 150*GM$Adj.Close + 21000, color = "GM")) + 
  geom_line(aes(date, t.s.fgp, color = "LJ fgp")) +
  geom_line(aes(date, t.s.bgp, color = "LJ bgp")) +
  geom_line(aes(date, .05*t.s.cp, color = "LJ cp"))


### function develooppp
#GM follows LJ, so no luck there
#Cor just for fun
cor(GM$Adj.Close, rogue$t.s.tgp, method = 'pearson', use = 'pairwise')
#Not bad
#should write function to do this for me when I import data
range(na.omit(GM$date))
a<-filter(GM, date>="2020-08-01")
b<-filter(rogue, date>= "2020-08-01")
cor(a$Adj.Close, b$t.s.tgp, method = "pearson", use = 'pairwise')
