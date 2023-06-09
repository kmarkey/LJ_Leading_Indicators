#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
# bslib instead of shiny dashboard
library(bslib)

library(tidyverse)
library(lubridate)

library(shinyWidgets)

KDAc <- read_csv("../data/sour/KDAc.csv", show_col_types = FALSE)
# generated on
today <- Sys.Date()

# last month
lmonth <- floor_date(floor_date(today, unit = "month") - 1, unit = "month")

# bounds of 2nd to last month on record
nmonth <- floor_date(floor_date(max(KDAc$date), unit = "month") - 1, unit = "month")
nomonth <- ceiling_date(nmonth, unit = "month") - 1

# bounds of last month on record
pmonth <- nomonth + 1
pqmonth <- ceiling_date(pmonth, unit = "month") - 1

# report would be made on the 1st of
repon <- pqmonth + 1

# report is for the month of
repfor <- paste0(month(pqmonth, label = TRUE, abbr = FALSE), ", ", year(pqmonth))

## ui.R ##

cards <- list(
  "text" = card(
    card_header("Text"),
    textOutput("text")
    ),
  
  "plot_history" = card(
    full_screen = TRUE,
    card_header("History"),
    plotOutput("plot_history")
  ),
  
  "plot_movers" = card(
    full_screen = TRUE,
    card_header("Biggest Movers"),
    plotOutput("plot_movers")
  )
)
cards[['text']]
# inputs

color_by <- varSelectInput("color_by", "Color by",
                           penguins[c("species", "island", "sex")],
                           selected = "species")

timeframe <- selectInput(
  "timeframe",
  "Select Timeframe:",
  choices = c(
    "All Time" = "all_time",
    "Past 5 Years" = "past_5",
    "Past Year" = "past_1",
    "Past 6 Months" = "past_6"
  ),
  selected = "all_time"
)

resolution <- selectInput(
  "resolution",
  "Select Resolution:",
  choices = c(
    "Yearly" = "year",
    "Monthly" = "month",
    "Weekly" = "week",
    "Daily" = "day"
  ),
  selected = "month"
)

purchase_lease <- checkboxGroupButtons(
  "purchase_lease",
  "Purchased/Leased:",
  choices = c("Purchased" = "P",
              "Leased" = "L"),
  selected = c("P", "L")
)

new_used <- checkboxGroupButtons(
  "new_used",
  "New/Used:",
  choices = c("New" = "NEW",
              "Used" = "USED"),
  selected = c("NEW", "USED")
)

metric <- selectInput(
  "metric",
  "Select Metric",
  choices = c(
    "Number of Sales" = "number_of_sales",
    "Front Gross Profit" = "front_gross_profit",
    "Back Gross Profit" = "back_gross_profit",
    "Total Gross Profit" = "total_gross_profit",
    "Cash Price" = "cash_price"
  ),
  selected = "number_of_sales"
)

new_used_movers <- checkboxGroupButtons(
  "new_used_movers",
  "New/Used:",
  choices = c("New" = "NEW",
              "Used" = "USED"),
  selected = c("NEW", "USED")
)

n_movers <- sliderInput(
  "n_movers",
  "Show Number",
  min = 2,
  max = 20,
  value = 10,
  step = 1
)

ui <- page_navbar(
  title = "LJ Leading Indicators",
  fluid = TRUE,
  nav_menu(
    title = "Business",
    value = "business",
    icon = icon("building"),
    
    # History
    nav_panel(
      title = "History",
      icon = icon("clock"),
      layout_sidebar(
        value = "history",
        cards[["plot_history"]],
        cards[['text']],
        sidebar = sidebar(timeframe, resolution, purchase_lease, new_used, metric)
      )
    ),
    
    # Movers
    nav_panel(
      "Biggest Movers",
      icon = icon("car"),
      layout_sidebar(
        value = "biggest-movers",
        cards["plot_movers"],
        sidebar = sidebar(new_used_movers, n_movers)
      )
    ),
    
    # Ranking
    nav_panel(
      "Ranking",
      icon = icon("ranking-star"),
      layout_sidebar(value = "ranking",
                     ####,
                     sidebar = "Ranking")
    )
  ),
  
  # personnel
  nav_menu(
    title = "Personnel",
    value = "personnel",
    align = "left",
    icon = icon("user-friends"),
    
    # salesman
    nav_panel("Top Salesman",
              value = "top-salesman",
              icon = icon("user-tie")),
    
    # finance
    nav_panel(
      "Top Finance Manager",
      value = "top-fi-manager",
      icon = icon("piggy-bank")
    )
  ),
  
  # prediction tab
  nav_panel(
    title = "Prediction",
    value = "prediction",
    icon = icon("cubes-stacked")
  ),
  
  nav_spacer(),
  
  # support menu
  nav_menu(
    title = "Support",
    align = "right",
    icon = icon("circle-exclamation"),
    
    nav_item(
      title = "Version",
      value = "version",
      tags$a("Last update:", repfor)
    ),
    
    nav_item(
      tags$a(icon("envelope"), "Maintenance Request", href = "https://forms.gle/mbG3dKhh5m1gZs176"),
    )
  )
)
