#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(shinyWidgets)

library(tidyverse)
library(lubridate)

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

header <- dashboardHeader(title = "LJ Leading Indicators",
                          dropdownMenu(type = "messages",
                               messageItem(
                                 from = "Version",
                                 message = "Product is up to date.",
                                 icon = icon("code-compare")
                                 ),
                               messageItem(
                                 from = "Support",
                                 message = "Submit a maintenance query.",
                                 icon = icon("circle-exclamation")
                                 ))
                          )


sidebar <- dashboardSidebar(
  sidebarMenu(
    
    menuItem("Business", tabName = "business", icon = icon("building"),
             startExpanded = T,
             menuSubItem("History", 
                         tabName = "history",
                         icon = icon("clock")),
             menuSubItem("Biggest Movers", 
                         tabName = "biggest-movers",
                         icon = icon("car")),
             menuSubItem("Ranking",
                         tabName = "ranking",
                         icon = icon("ranking-star"))),
    
    menuItem("Personnel", tabName = "personnel",  icon = icon("user-friends"),
             menuSubItem("Top Salesman", 
                         tabName = "top-salesman",
                         icon = icon("user-tie")),
             menuSubItem("Top Finance Manager", 
                         tabName = "top-fi-manager",
                         icon = icon("piggy-bank"))),
    menuItem("Prediction", tabName = "prediction", icon = icon("cubes-stacked"),
             badgeLabel = "dev", badgeColor = "orange")
  )
)

body <- dashboardBody(
  tabItems(
    tabItem(tabName = "history",
            column(12, 
            
              # dateRangeInput("daterange", label = "Input Date Range", 
              #                start = min(KDAc$date), end = pqmonth, 
              #                min = min(KDAc$date), max = pqmonth),
              # 
              fluidRow(
                column(6,
                       
                  selectInput("timeframe", "Select Timeframe:", 
                              choices = c("All Time" = "all_time", 
                                          "Past 5 Years" = "past_5", 
                                          "Past Year" = "past_1", 
                                          "Past 6 Months" = "past_6"),
                              selected = "all_time")
                  ),
                column(6,
                       
                  selectInput("resolution", "Select Resolution:", 
                              choices = c("Yearly" = "year", 
                                          "Monthly" = "month", 
                                          "Weekly" = "week", 
                                          "Daily" = "day"),
                              selected = "month"),
                  )),
              
              fluidRow(
                column(6,
    
                  checkboxGroupInput("purchase_lease", "Purchased/Leased:",
                              choices = c("Purchased" = "P", 
                                          "Leased" = "L"),
                              selected = c("P", "L"),
                              inline = TRUE)
                ),
              
                column(6,
              
                  checkboxGroupInput("new_used", "New/Used:",
                                     choices = c("New" = "NEW", 
                                                 "Used" = "USED"), 
                                     selected = c("NEW", "USED"),
                                     inline = TRUE)
                )),
            
              fluidRow(
                column(12,
                       
                  selectInput("metric", "Select Metric",
                              choices = c("Number of Sales" = "number_of_sales",
                                          "Front Gross Profit" = "front_gross_profit",
                                          "Back Gross Profit" = "back_gross_profit",
                                          "Total Gross Profit" = "total_gross_profit",
                                          "Cash Price" = "cash_price"),
                              selected = "number_of_sales")
                )),
              fluidRow(
                column(12,
                  
                  actionBttn("run", "Run"))),
              
              br(),
            
              br(),

              #plotOutput("plot")
            # dateInput(
            #   "last-6-months-date",
            #   label = "Select Month",
            #   value = NULL,
            #   min = NULL,
            #   max = NULL,
            #   format = "yyyy-mm",
            #   startview = "year",
            #   weekstart = 0,
            #   language = "en",
            #   width = NULL,
            #   autoclose = TRUE,
            #   datesdisabled = NULL,
            #   daysofweekdisabled = NULL
            #), 
              plotOutput("plot_history")
            )
    ),

    tabItem(tabName = "biggest-movers",
            column(12,
                   
                   fluidRow(
                     column(12,
                       checkboxGroupInput("new_used_movers", "New/Used:",
                                          choices = c("New" = "NEW", 
                                                      "Used" = "USED"), 
                                          selected = c("NEW", "USED"),
                                          inline = TRUE),
                       
                      sliderInput("n_movers", "Show Number", 
                                  min = 2,
                                  max = 20,
                                  value = 10, 
                                  step = 1)
                      )
                    ) # auto update no run button
                   ),
            plotOutput("plot_movers")
    )
  )
)


# maintenance

# Put them together into a dashboardPage

shinydashboard::dashboardPage(
  header,
  sidebar,
  body
)
