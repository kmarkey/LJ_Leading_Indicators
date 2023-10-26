#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(extrafont)
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

tags$style(HTML("
      @import url('https://fonts.googleapis.com/css2?family=Yusei+Magic&display=swap');
      body {
        background-color: black;
        color: white;
      }
      h2 {
        font-family: 'Yusei Magic', sans-serif;
      }
      .span.bootstrap-switch {
        color: red;
      }"))


#switchInput color while on
#switchInput color while on
tags$head(tags$style(HTML('.bootstrap-switch .bootstrap-switch-handle-off.bootstrap-switch-on,
                                       .bootstrap-switch .bootstrap-switch-handle-on.bootstrap-switch-on {
                                        background: --bs-green;
                                        color: --bs-white;
                                        }')))

#switchInput color while off
tags$head(tags$style(HTML('.bootstrap-switch .bootstrap-switch-handle-off.bootstrap-switch-off,
                                       .bootstrap-switch .bootstrap-switch-handle-on.bootstrap-switch-off {
                                        background: --bs-red;
                                        color: --bs-black;
                                        }')))

month_select <- selectInput(
  "month_select",
  "Select Month:",
  choices = month_choices,
  selected = selected_month
)

month_select_personnel <- selectInput(
  "month_select_personnel",
  "Select Month:",
  choices = month_choices,
  selected = selected_month
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

purchase_lease_movers <- checkboxGroupButtons(
  "purchase_lease_movers",
  "Purchased/Leased:",
  choices = c("Purchased" = "P",
              "Leased" = "L"),
  selected = c("P", "L")
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

n_months <- numericInput(
  inputId = "n_months",
  label = NULL,
  value = 5,
  max = month(pmonth),
  width = "80px")

n_years <- numericInput(
  inputId = "n_years",
  label = NULL,
  value = 3,
  width = "80px"
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

features_filter <- switchInput(
  "features_filter",
  "Show All Leads",
  value = FALSE
)

lasso_switch <- switchInput(
  inputId = "lasso_model",
  label = "Linear",
  value = FALSE,
  onStatus = "on",
  offStatus = "off"
)

tree_switch <- switchInput(
  "tree_model",
  "Decision Tree",
  value = FALSE,
  onStatus = "on",
  offStatus = "off"
)

random_switch <- switchInput(
  "random_model",
  "Random Forest",
  value = FALSE,
  onStatus = "on",
  offStatus = "off"
)

arima_switch <- switchInput(
  "arima_model",
  "ARIMA",
  value = FALSE,
  onStatus = "on",
  offStatus = "off"
)

gru_switch <- switchInput(
  "gru_model",
  "GRU",
  value = FALSE,
  onStatus = "on",
  offStatus = "off"
)

lstm_switch <- switchInput(
  "lstm_model",
  "LSTM",
  value = FALSE,
  onStatus = "on",
  offStatus = "off"
)

ui <- page_navbar(
  title = "Leading Indicators",
  id  = "root",
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
        id = "history",
        
        sidebar = sidebar(metric, resolution, purchase_lease, new_used),
        # type = "hidden",
        #full_screen = TRUE,
        #title = "History",
        
        nav_panel(
          title = "Time Series",
          value = "timeseries",
          shinyjs::useShinyjs(),
          
          card(full_screen = TRUE,
               plotlyOutput("plot_history"))
        ),
        
        nav_panel(
          title = "Month Order",
          value =
            "monthorder",
          shinyjs::useShinyjs(),
          # tags$head(
          #   tags$style(
          #     type = "text/css",
          #     #"{ display: table-cell; text-align: right; vertical-align: middle; }
          #     #".form-group { display: table-row; }"
          #   )
          # ),

          card(
            fluidRow("Showing", n_months, " months and ", n_years, "years")
            ),
          
          card(
            plotlyOutput("plot_last_year")
          )
        )
      )
    ),
    
    # Movers
    nav_panel(
      title = "Biggest Movers",
      value = "biggestmovers",
      icon = icon("car"),
      layout_sidebar(
        value = "biggest-movers",
        card(full_screen = TRUE,
             plotlyOutput("plot_movers")),
        
        sidebar = sidebar(
          month_select,
          purchase_lease_movers,
          new_used_movers,
          n_movers
        )
      )
    )
    

  ),
  
  # personnel
  
  # make these value boxes!!!
  nav_panel(
    title = "Personnel",
    value = "personnel",
    icon = icon("user-tie"),
    
    layout_sidebar(
      value = "personnel-sidebar",
      
      layout_column_wrap(
        width = 1,
        height = 1 / 2,
        card(
          full_screen = TRUE,
          card_header("Top Salesmen"),
          plotOutput("plot_top_salesmen")
        ),
        
        layout_column_wrap(
          width = 1 / 2,
          height = 1 / 2,
          card(
            full_screen = TRUE,
            card_header("Top Sales Managers"),
            plotOutput("plot_top_salesmanager")
          ),
          card(
            full_screen = TRUE,
            card_header("Top Finance Managers"),
            plotOutput("plot_top_fi")
          )
        )
      ),
      sidebar = sidebar(month_select_personnel, metric3, n_performers)
    )
  ),
  
  # prediction tab
  nav_panel(
    title = "Leading Indicators",
    value = "leadingindicators",
    icon = icon("bolt-lightning"),

    layout_sidebar(
      card(
        full_screen = TRUE,
        column(width = 12,
               DT::DTOutput("info_table"), 
               style = "overflow-y: scroll")
      ),
      sidebar = sidebar(features_filter)
    )
  ),
  
  nav_panel(
    title = "Prediction",
    value = "prediction",
    icon = icon("cubes-stacked"),
    
    tags$head(
      tags$style(
        type = "text/css",
        "#inline label{ display: table-cell; text-align: right; vertical-align: middle; }
                #inline .form-group { display: table-row;}"
      )
    ),
    
    layout_sidebar(
      card(full_screen = TRUE,
           plotlyOutput("prediction")),
      sidebar = sidebar(lasso_switch,
                        tree_switch,
                        random_switch,
                        arima_switch,
                        gru_switch,
                        lstm_switch)
    )
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
      tags$a("Last update:", maxdate)
    ),
    
    # link to form for maintenance
  )
)
