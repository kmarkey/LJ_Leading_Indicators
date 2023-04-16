#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
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

library(tidyverse)

source("../aesthetics/theme-and-palette.R")

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

group_unit <- function(group) {
  if (group == "daily") {
    return("day")
  } else return(substr(group, 1, nchar(group) - 2))
}

function(input, output, session) {
  # first 6 months tab
    # first_months <- reactiveValues(daterange = c("2022-01-01", "2022-02-02"),
    #                                timeframe = "all_time",
    #                                resolution = "monthly",
    #                                purchase_lease = "both",
    #                                metric = "n",
    #                                new_used = "new",
    #                                data = NULL)
    
    # a <- bindEvent(reactive(input$all_time),
    #                      
    #                      
    #             
    #           # observe(input$all_time),
    #           # observe(input$past_5),
    #           # observe(input$past_1),
    #           # observe(input$past_6), 
    #           # reactive(input$daterange), 
    #           {
    #   output$text <- renderText(paste0(input$all_time))
    #   data <- NULL
    # })
    
    # bindEvent(observe(input$all_time), {
    #   
    #   output$text <- renderText(paste0(input$daterange))
    # })
    
    # b <- bindEvent(reactive(input$monthly), {
    #   
    #   output$text <- renderText(paste0(input$monthly, "monthly"))
    #   data <- runif(100)
    #   
    # })
    # 
    # c <- bindEvent(reactive(input$weekly), observe(input$weekly), {
    #   
    #   output$text <- renderText(paste0(input$weekly, "weekly"))
    #   data <- runif(100)
    #   
    # })
    # fm <- reactiveValues(timeframe = "all_time",
    #                      resolution = "yearly",
    #                      purchase_lease = c("P", "L"),
    #                      new_used = c("N", "U"),
    #                      metric = "number_of_sales",
    #                      data = NULL)
    
    # (input$run, { fm$timeframe <- input$timeframe
    #                           fm$resolution <- input$resolution
    #                           fm$purchase_lease <- input$purchase_lease
    #                           fm$metric <- input$metric
    #                           fm$new_used <- input$new_used })
    # 
    # calculate values

  
    
    output$plot_history <- renderPlot({
      
      # reactive expression function for timeframe conversion
      timeframe_f <- reactive({
        case_when(
          input$timeframe == "all_time" ~ as.Date(c(min(KDAc$date), max(KDAc$date))),
          input$timeframe == "past_5" ~ as.Date(c(max(KDAc$date) - years(5), max(KDAc$date))),
          input$timeframe == "past_1" ~ as.Date(c(max(KDAc$date) - years(1), max(KDAc$date))),
          input$timeframe == "past_6" ~ as.Date(c(max(KDAc$date) - months(6, abbreviate = FALSE), max(KDAc$date))), 
        )
      })
      
      # begin plotting
      KDAc %>%
        
        # timeframe
        dplyr::filter(between(date, timeframe_f()[1], timeframe_f()[2])) %>%
        
        # purchased or leased
        {
          if ((all(input$purchase_lease == "P") |
               all(input$purchase_lease == "L")) & !is.null(input$purchase_lease))
            
            dplyr::filter(., pl == input$purchase_lease)
          
          else
            .
        } %>%
        
        # new used
        {
          if ((all(input$new_used == "NEW") |
               all(input$new_used == "USED")) & !is.null(input$new_used))
            
            dplyr::filter(., nu == input$new_used) # this and last month
          else
            .
        } %>%
        
        #  resolution
        dplyr::group_by(!!paste(input$resolution) := floor_date(date,!!input$resolution)) %>%
        
        # metric
        {
          if (input$metric == "number_of_sales")
            
            dplyr::summarise(., number_of_sales = n(), date)
          
          else
            
            dplyr::summarise(.,!!paste(input$metric) := mean(get(input$metric), na.rm = TRUE), date)
        } %>%
        
        ggplot() +
        
        geom_line(aes(x = date, y = get(input$metric)), color = blue, linewidth = 2) +
        
        geom_line(aes(x = date, y = get(input$metric)), color = lightblue, linewidth = 1) +
        
        labs(x = str_to_title(input$resolution),
             y = paste(str_to_title(str_replace_all(input$metric, "_", " ")))) +
        
        # always show 0
        expand_limits(y = 0) +
        
        coord_cartesian(xlim = c(timeframe_f()[1], timeframe_f()[2]))+
        
        # add theme
        ljtheme()
      
    }, height = 600) %>% 
      
      bindEvent(input$run)
    
    output$plot_movers <- renderPlot({
      
      # get data, always for current month
      data <- KDAc %>%
        
        {if ((all(input$new_used_movers == "NEW") |
              all(input$new_used_movers == "USED")) & !is.null(input$new_used_movers))
          
          dplyr::filter(., nu == input$new_used_movers, date >= nmonth, date <= pqmonth) # this and last month
          else 
            dplyr::filter(., date >= nmonth, date <= pqmonth)
        } %>%
        
        {if (all(input$new_used_movers == "USED")) 
          dplyr::mutate(., carname = str_c(make, " ", model), .keep = 'unused')
          else # Only by model, not by year
            dplyr::mutate(., carname = str_c(make, " ", model, " ", caryear), .keep = 'unused')} %>%
        
        dplyr::group_by(carname, month = ifelse(month(date) == month(pqmonth), "current", "last")) %>% # change month names
        
        dplyr::summarise(n = n()) %>%
        
        pivot_wider(id_cols = "carname", names_from = "month", values_from = "n", values_fill = 0) %>%
        
        dplyr::mutate(change = current - last) %>%
        
        ungroup() %>%
        
        slice_max(n = input$n_movers, order_by = abs(change), with_ties = FALSE)
      
      
      # doesnt look quite right???
      
      # start plotting
      data %>%
        
        ggplot() +
        
        geom_segment(
          aes(
            x = reorder(carname, change),
            y = last,
            xend = carname,
            yend = current,
            color = change > 0
          ),
          linewidth = 10,
          lineend = "round"
        ) +
        
        geom_point(
          aes(x = carname, y = current),
          color = "black",
          alpha = 0.2,
          size  = 10
        ) +
        
        
        geom_segment(
          aes(
            x = reorder(carname, change),
            y = ifelse(change > 0, current + 0.5, current - 0.5),
            xend = carname,
            yend = last
          ),
          color = "white",
          linewidth = 1.1,
          lineend = "round",
          linejoin = "bevel",
          arrow = arrow(length = unit(0.15, "in"), ends = "first")
        ) +
        
        theme(axis.text.x = element_text(
          angle = 90,
          hjust = 1,
          vjust = 0.5
        ),
        legend.position = "none") +
        
        scale_color_manual(values = c(red, green)) +
        
        labs(
          title = paste0("Biggest Movers This Month (", input$new_used_movers, ")"),
          subtitle = repfor,
          x = "",
          y = "Change In Sales"
        )
      
    }) %>%
      # dependent on all user params
      bindEvent(input$new_used_movers, input$n_movers)
    
    output$text <- renderText(class(input$timeframe[1]))
    
    }

