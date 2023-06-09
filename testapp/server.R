
#
#    http://shiny.rstudio.com/

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


server <- function(input, output) {

    # calculate values
    timeframe_f <- function(t) {
      case_when(
        t == "all_time" ~ as.Date(c(min(KDAc$date), max(KDAc$date))),
        t == "past_5" ~ as.Date(c(
          max(KDAc$date) - years(5), max(KDAc$date)
        )),
        t == "past_1" ~ as.Date(c(
          max(KDAc$date) - years(1), max(KDAc$date)
        )),
        t == "past_6" ~ as.Date(c(
          max(KDAc$date) - months(6, abbreviate = FALSE), max(KDAc$date)
        ))
      )
    }
    
    output$plot_history <- renderPlot({
      
      data <- KDAc %>%
        
        # timeframe
        dplyr::filter(between(
          date,
          timeframe_f(input$timeframe)[1],
          timeframe_f(input$timeframe)[2]
        )) %>%
        
        # purchased or leased
        {
          if ((all(input$purchase_lease == "P") |
               all(input$purchase_lease == "L")) &
              !is.null(input$purchase_lease))
            
            dplyr::filter(., pl == input$purchase_lease)
          
          else
            .
          
        } %>%
        
        # new used
        {
          if ((all(input$new_used == "NEW") |
               all(input$new_used == "USED")) &
              !is.null(input$new_used))
            
            dplyr::filter(., nu == input$new_used) # this and last month
          
          else
            .
        } %>%
        
        #  resolution
        dplyr::group_by(., !!input$resolution := floor_date(date, input$resolution)) %>%
        
        # metric
        {
          if (input$metric == "number_of_sales")
            
            dplyr::summarise(., number_of_sales = n(), date)
          
          else
            
            dplyr::summarise(., !!input$metric := mean(get(input$metric), na.rm = TRUE), date)
        }
      
      ggplot(data) +
        
        geom_line(aes(x = date, y = get(input$metric)),
                  color = blue,
                  linewidth = 2) +
        
        labs(x = str_to_title(input$resolution),
             y = paste(str_to_title(str_replace_all(
               input$metric, "_", " "
             )))) +
        
        # always show 0
        expand_limits(y = 0) +
        
        coord_cartesian(xlim = c(timeframe_f(input$timeframe)[1], timeframe_f(input$timeframe)[2]))
    }
    )
    
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
          linejoin = "bevel"
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
      
    }
    )
    
    output$text <- renderText({
        
        data <- KDAc %>%
        
        # timeframe
        dplyr::filter(between(
          date,
          timeframe_f(input$timeframe)[1],
          timeframe_f(input$timeframe)[2]
        )) %>%
        
        # purchased or leased
        {
          if ((all(input$purchase_lease == "P") |
               all(input$purchase_lease == "L")) &
              !is.null(input$purchase_lease))
            
            dplyr::filter(., pl == input$purchase_lease)
          
          else
            .
          
        } %>%
        
        # new used
        {
          if ((all(input$new_used == "NEW") |
               all(input$new_used == "USED")) &
              !is.null(input$new_used))
            
            dplyr::filter(., nu == input$new_used) # this and last month
          
          else
            .
        } %>%
        
        #  resolution
        dplyr::group_by(., !!input$resolution := floor_date(date, input$resolution)) %>%
        
        # metric
        {
          if (input$metric == "number_of_sales")
            
            dplyr::summarise(., number_of_sales = n(), date)
          
          else
            
            dplyr::summarise(., !!input$metric := mean(get(input$metric), na.rm = TRUE), date)
        }
        
        ncol(data)
        }
    )
    }
