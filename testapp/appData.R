# appData

library(tidyverse)
library(here)
library(lubridate)
library(logger)
library(scales)

KDAc <- read_csv("data/sour/KDAc.csv")
here()

# generated on
today <- Sys.Date()

# bounds of 2nd to last month on record
pmonth <- floor_date(floor_date(max(KDAc$date), unit = "month") - 1, unit = "month")
pomonth <- ceiling_date(pmonth, unit = "month") - 1

# last month on record
nmonth <- pomonth + 1
nomonth <- ceiling_date(nmonth, unit = "month") - 1

# days behind
today - nomonth

# report is for the month of
repfor <- paste0(month(nomonth, label = TRUE, abbr = FALSE), ", ", year(nomonth))

n.months <- 10

metric <- "n"

metric_dict <- c(n = "Total Sales", 
                 front_gross_profit = "Avg. Front Gross Profit", 
                 back_gross_profit = "Avg. Back Gross Profit",
                 total_gross_profit = "Avg. Total Gross Profit",
                 cash_price = "Avg. Cash Price")

mlabs <- function(x) {
  paste0(month(
    pmonth - months(as.numeric(x)),
    label = TRUE,
    abbr = FALSE
  ))
}

mgroups <- KDAc %>%
  
  dplyr::mutate(mgroup = factor(month(pmonth) - month(date), ordered = TRUE),
                theyear = year(date)) %>%
  
  group_by(mgroup, theyear) %>%
  
  {if (metric == "n")
    summarise(., y = n(), mgroup, theyear)
    else
      summarise(., y = mean(get(metric), na.rm = TRUE), mgroup, theyear)} %>%
  
  distinct() %>%
  
  dplyr::filter(theyear >= year(pmonth) - 1, mgroup <= n.months - 1 &&
                  mgroup >= 0)

ggplot() +
  geom_bar(
    data = mgroups %>% dplyr::filter(theyear == year(pmonth)),
    aes(x = mgroup, y = y),
    width = 0.7,
    stat = "identity",
    fill = lightblue,
    alpha = 0.8
  ) +
  
  geom_line(
    data = mgroups %>% dplyr::filter(theyear == year(pmonth) - 1),
    aes(x = mgroup, y = y, group = theyear),
    lwd = 1.5,
    lty = 9,
    alpha = 0.6
  ) +
  
  geom_label(
    data = mgroups %>% dplyr::filter(theyear == year(pmonth) - 1, mgroup == n.months - 1),
    aes(x = mgroup, y = y - 10, label = "Last Year"),
    fill = "black",
    color = "white"
  ) +
  
  {if (metric == "n") 
    geom_label(data = mgroups %>% dplyr::filter(theyear == year(pmonth)),
               aes(x = mgroup, y = y, label = comma(round(y))))
    else
      geom_label(data = mgroups %>% dplyr::filter(theyear == year(pmonth)),
                 aes(x = mgroup, y = y, label = paste0("$", comma(round(y)))))
  } +
  
  scale_x_discrete(labels = mlabs, limits = rev) +
  
  scale_y_continuous(labels = comma) +
  
  labs(
    title = paste0(metric_dict[metric], " in the Last ", n.months, " Months"),
    subtitle = paste0("From ", repfor),
    y = '',
    x = ''
  )
