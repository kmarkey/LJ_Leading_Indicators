#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define server logic required to draw a histogram
# shinyServer(function(input, output) {
# 
#     
#   
#   
#   
#   output$distPlot <- renderPlot({
# 
#         # generate bins based on input$bins from ui.R
#         x    <- faithful[, 2]
#         bins <- seq(min(x), max(x), length.out = input$bins + 1)
# 
#         # draw the histogram with the specified number of bins
#         hist(x, breaks = bins, col = 'darkgray', border = 'white',
#              xlab = 'Waiting time to next eruption (in mins)',
#              main = 'Histogram of waiting times')
# 
#     })
# 
# })
KDAc <- read_csv("data/sour/KDAc.csv")

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

# aesthetics
source("aesthetics/theme-and-palette.R")

shinyServer(input, output)
  