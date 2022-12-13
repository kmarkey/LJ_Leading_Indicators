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

# aesthetics
pal <- c("#f6aa1c","#08415c","#6b818c","#eee5e9","#ba7ba1","#c28cae","#a52a2a")

blue <- "#114482"
lightblue <- "#146ff8"
llightblue <- "#AFCFFF"
red <- "#a52a2a"
white <- "#FBFFF1"
yellow <- "#F6AA1C"
green <- "#588157"

#================================== func =======================================
integer_breaks <- function(n = 5, ...) {
  fxn <- function(x) {
    breaks <- floor(pretty(x, n, ...))
    names(breaks) <- attr(breaks, "labels")
    breaks
  }
  return(fxn)
}

movers_menu <- c("NEW", "USED")

movers <- KDAc %>%
  dplyr::filter(nu == "NEW", date >= pmonth - months(1), date <= pomonth) %>% # this and last month
  dplyr::mutate(carname = str_c(make, " ", model, " ", caryear), .keep = 'unused') %>%
  dplyr::group_by(carname, month = ifelse(month(date) == month(pmonth), "current", "last")) %>% # change month names
  dplyr::summarise(n = n()) %>%
  pivot_wider(id_cols = "carname", names_from = "month", values_from = "n", values_fill = 0) %>%
  
  dplyr::mutate(change = current - last) %>%
  ungroup() %>%
  slice_max(n = 10, order_by = abs(change), with_ties = FALSE)


movers_plot <- newmonth %>%
  ggplot() + geom_segment(aes(x = reorder(carname, last), y = last, xend = carname, yend = current, color = change < 0),
                            size = 3, lineend = "round", linejoin = "bevel",
                            arrow = arrow(length = unit(0.2, "inches"), ends = "first")) +
  theme(axis.text.x = element_text(angle = -25),
        legend.position = "none") +
  scale_color_manual(values = c(red, green)) +
  labs(title = "Biggest Movers This Month for New Cars",
       subtitle = repfor, 
       x = "",
       y = "Change In Sales This Month")
