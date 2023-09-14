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
library(plotly)

source("appData.R")
## ui.R ##

# inputs

month_select <- selectInput(
  "month_select",
  label = NULL,
  choices = month_choices,
  selected = selected_month
)


# timeframe <- selectInput(
#   "timeframe",
#   "Select Timeframe:",
#   choices = c(
#     "All Time" = "all_time",
#     "Past 5 Years" = "past_5",
#     "Past Year" = "past_1",
#     "Past 6 Months" = "past_6"
#   ),
#   selected = "all_time"
# )

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
  "Number of Movers",
  min = 2,
  max = 20,
  value = 10,
  step = 1
)

n_months <- sliderInput(
  "n_months",
  "Number of Months",
  min = 1,
  max = month(pmonth),
  value = 1,
  step = 1
)

n_years <- sliderInput(
  "n_years",
  "Number of Years",
  min = 1,
  max = 10,
  value = 3,
  step = 1
)

metric2 <- selectInput(
  "metric2",
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

metric3 <- selectInput(
  "metric3",
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

n_performers <- sliderInput(
  "n_performers",
  "Number of People",
  min = 2,
  max = 10,
  value = 5,
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
      
      navset_card_tab(
        full_screen = TRUE,
        title = "History",
        
        nav_panel(
          "Time Series",
          card_title("Time Series"),
          
          card(
            layout_sidebar(
              value = "history",
              full_screen = TRUE,
              plotlyOutput("plot_history"),
              sidebar = sidebar(metric, resolution, purchase_lease, new_used)
            )
          )
        ),
        
        nav_panel(
          "Month Order",
          card_title("Month Order"),
          
          card(
            layout_sidebar(
              value = "last_year",
              full_screen = TRUE,
              plotlyOutput("plot_last_year"),
              sidebar = sidebar(metric2, n_months, n_years)
            )
          )
        )
      )
    ),
    
    # Movers
    nav_panel(
      "Biggest Movers",
      icon = icon("car"),
      layout_sidebar(
        value = "biggest-movers",
        card(
          full_screen = TRUE,
          plotlyOutput("plot_movers")
        ),
        sidebar = sidebar(new_used_movers, n_movers)
      )
    )
    
    # Ranking
    # nav_panel(
    #   "Ranking",
    #   icon = icon("ranking-star"),
    #   card(full_screen = TRUE,
    #        card_header(paste0("Ranking ", repfor)),
    #        plotlyOutput("plot_rank"))
    # )
  ),
  
  # personnel
  nav_menu(
    title = "Personnel",
    value = "personnel",
    icon = icon("user-friends"),
    
    # salesman
    nav_panel(
      "Top Performers",
      icon = icon("user-tie"),
      layout_sidebar(
        value = "top-performers",
        card(
          full_screen = TRUE,
          card_header("Top Salesmen"),
          plotOutput("plot_top_salesmen")
        ),
        card(
          full_screen = TRUE,
          card_header("Top Finance Manager"),
          plotOutput("plot_top_fi")
        ),
        sidebar = sidebar(metric3, n_performers)
      )
    )
  ),
  
  # prediction tab
  nav_panel(
    title = "Machine Learning",
    value = "machine_learning",
    icon = icon("cubes-stacked")
  ),
  
  nav_spacer(),
  
  nav_item(month_select),
  
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
      tags$a(icon("envelope"), "Maintenance Request", href = "https://forms.gle/mbG3dKhh5m1gZs176")
    )
  )
)
