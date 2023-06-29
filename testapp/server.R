#
#    http://shiny.rstudio.com/

library(tidyverse)
library(scales)

source("../aesthetics/theme-and-palette.R")

theme_set(ljtheme())

## THEME
source("appData.R")


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
        max(KDAc$date) - months(6, abbreviate = FALSE),
        max(KDAc$date)
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
      dplyr::group_by(.,
                      !!input$resolution := floor_date(date, input$resolution)) %>%
      
      # metric
      {
        if (input$metric == "number_of_sales")
          
          dplyr::summarise(., number_of_sales = n(), date)
        
        else
          
          dplyr::summarise(.,!!input$metric := mean(get(input$metric), na.rm = TRUE), date)
      }
    
    ggplot(data) +
      
      geom_line(aes(x = date, y = get(input$metric)),
                color = blue,
                linewidth = 2) +
      
      labs(x = str_to_title(input$resolution),
           y = paste(str_to_title(
             str_replace_all(input$metric, "_", " ")
           ))) +
      
      {
        if (input$metric != 'number_of_sales')
          scale_y_continuous(labels = comma)
      } +
      
      # always show 0
      expand_limits(y = 0) +
      
      coord_cartesian(xlim = c(
        timeframe_f(input$timeframe)[1],
        timeframe_f(input$timeframe)[2]
      ))
  })
  
  output$plot_last_year <- renderPlot({
    mlabs <- function(x) {
      paste0(month(
        pmonth - months(as.numeric(x)),
        label = TRUE,
        abbr = FALSE
      ))
    }
    
    # group by distance from current month
    data <- KDAc %>%
      
      dplyr::mutate(mgroup = factor(month(pmonth) - month(date), ordered = TRUE),
                    theyear = year(date)) %>%
      
      group_by(mgroup, theyear) %>%
      
      {
        if (input$metric2 == "number_of_sales")
          summarise(., y = n(), mgroup, theyear)
        else
          summarise(., y = mean(get(input$metric2), na.rm = TRUE), mgroup, theyear)
      } %>%
      
      distinct() %>%
      
      dplyr::filter(
        theyear >= year(pmonth) - input$n_years + 1,
        as.numeric(as.character(mgroup)) >= 0 &&
          as.numeric(as.character(mgroup)) <= input$n_months - 1
      )
    
    ggplot() +
      geom_col(
        data = data,
        aes(
          x = rev(mgroup),
          y = y,
          group = theyear,
          fill = theyear
        ),
        width = 0.8,
        position = 'dodge',
      ) +
      
      geom_text(
        data = data,
        aes(
          x = rev(mgroup),
          y = 0,
          group = theyear,
          label = theyear,
          color = y < 5
        ),
        position = position_dodge(width = 0.8),
        angle = 90,
        hjust = -0.1
      ) +
      
      scale_x_discrete(labels = mlabs, limits = rev) +
      
      scale_y_continuous(labels = comma) +
      
      scale_color_manual(values = c("white", "black")) +
      
      labs(x = '',
           y = paste(str_to_title(
             str_replace_all(input$metric2, "_", " ")
           ))) +
      
      theme(legend.position = 'none')
  })
  
  output$plot_movers <- renderPlot({
    # get data, always for current month
    data <- KDAc %>%
      
      {
        if ((all(input$new_used_movers == "NEW") |
             all(input$new_used_movers == "USED")))
          
          dplyr::filter(.,
                        nu == input$new_used_movers,
                        date >= nmonth,
                        date <= pqmonth) # this and last month
        
        else
          dplyr::filter(., date >= nmonth, date <= pqmonth)
      } %>%
      
      {
        if (all(input$new_used_movers == "USED"))
          dplyr::mutate(., carname = str_c(make, " ", model), .keep = 'unused')
        else
          # Only by model, not by year
          dplyr::mutate(.,
                        carname = str_c(make, " ", model, " ", caryear),
                        .keep = 'unused')
      } %>%
      
      dplyr::group_by(carname, month = ifelse(month(date) == month(pqmonth), "current", "last")) %>% # change month names
      
      dplyr::summarise(n = n()) %>%
      
      pivot_wider(
        id_cols = "carname",
        names_from = "month",
        values_from = "n",
        values_fill = 0
      ) %>%
      
      dplyr::mutate(change = current - last) %>%
      
      ungroup() %>%
      
      slice_max(
        n = input$n_movers,
        order_by = abs(change),
        with_ties = FALSE
      )
    
    # plotting
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
          y = current,
          xend = carname,
          yend = last
        ),
        color = "white",
        linewidth = 1.1,
        lineend = "round",
        linejoin = "bevel"
      ) +
      
      geom_point(
        aes(x = carname, y = current, shape = change > 0),
        color = "white",
        fill = "white",
        size  = 4
      ) +
      
      theme(
        axis.text.x = element_text(
          angle = 90,
          hjust = 1,
          vjust = 0.5
        ),
        
        legend.position = "none"
      ) +
      
      scale_color_manual(values = c(red, green)) +
      scale_shape_manual(values = c(25, 24)) +
      scale_y_continuous(breaks = integer_breaks()) +
      labs(x = "",
           y = "Change In Sales")
    
  })
  
  output$plot_rank <-  renderPlot({
    data <- KDAc %>%
      dplyr::filter(month(date) == month(pmonth), year(date) <= year(pmonth)) %>%
      group_by(theyear = year(date)) %>%
      dplyr::transmute(
        `Cash Price` = mean(cash_price, na.rm = TRUE),
        `Total Gross Profit` = sum(total_gross_profit, na.rm = TRUE),
        `Back Gross Profit` = sum(back_gross_profit, na.rm = TRUE),
        `Front Gross Profit` = sum(front_gross_profit, na.rm = TRUE),
        `New Sales` = sum(ifelse(nu == "NEW", 1, 0)),
        `Used Sales` = sum(ifelse(nu == "USED", 1, 0)),
      ) %>%
      distinct() %>%
      
      pivot_longer(!theyear, names_to = "name", values_to = "value") %>%
      group_by(name = factor(
        name,
        levels = c(
          "Total Gross Profit",
          # ordered
          "Back Gross Profit",
          "Front Gross Profit",
          "Cash Price",
          "New Sales",
          "Used Sales"
        ),
        ordered = TRUE
      )) %>%
      
      mutate(ranks = order(order(value, decreasing = TRUE)), # actual ranks
             rankval = rank(value)) # numeric bar chart value
    
    ggplot(data) +
      geom_bar(aes(x = theyear, y = rankval, fill = rankval),  stat = "identity") +
      facet_wrap( ~ name) +
      geom_text(aes(x = theyear, y = rankval / 2, label = ranks), color = white) +
      scale_fill_gradient2(
        midpoint = 3,
        low = red,
        mid = llightblue,
        high = blue
      ) +
      labs(x = '',
           y = '') +
      theme(
        legend.position = "none",
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank()
      )
  })
  
  output$plot_top_salesmen <- renderPlot({
      
    data <- KDAc %>%
      
      dplyr::filter(date >= pmonth, date <= pqmonth) %>%
      
      group_by(salesman) %>%
      
      # metric
      {
        if (input$metric3 == "number_of_sales")
          
          dplyr::summarise(., metric = n())
        
        else
          
          dplyr::summarise(., metric = mean(get(input$metric3), na.rm = TRUE))
      } %>%
      
      distinct() %>%
      
      slice_max(n = input$n_performers,
                order_by = metric)
    
    # plotting
    data %>%
      ggplot() + geom_bar(aes(x = reorder(salesman, metric),
                              y = metric),
                          stat = "identity") +
      
      {
        if (input$metric3 == "number_of_sales")
          geom_label(aes(
            x = salesman,
            y = metric,
            label = paste0(salesman, "\n", round(metric, digits = 0))
          ),
          size = 3)
        
        else
          geom_label(
            aes(
              x = salesman,
              y = metric,
              label = paste0(salesman, "\n$", scales::comma(round(metric, digits = 0)))
            ),
            size = 3)
      } +
      # geom_label(aes(x = salesman,
      #                y = get(input$metric3),
      #                label = paste0(salesman, "\n", scales::comma(round(get(input$metric3), digits = 0)))),
      #            size = 3) +
      
      labs(y = "",
           x = "") +
      
      scale_y_continuous(expand = expansion(mult = c(-0.3, 0.1)),
                         breaks = integer_breaks(),
                         labels = comma) +
      
      theme(axis.text.x = element_blank(),
            axis.ticks.x = element_blank())
  })
  
  output$plot_top_fi <- renderPlot({
    
    data <- KDAc %>%
      
      dplyr::filter(date >= pmonth, date <= pqmonth) %>%
      
      group_by(fimanager) %>%
      
      # metric
      {
        if (input$metric3 == "number_of_sales")
          
          dplyr::summarise(., metric = n())
        
        else
          
          dplyr::summarise(., metric = mean(get(input$metric3), na.rm = TRUE))
      } %>%
      
      distinct() %>%
      
      slice_max(n = input$n_performers,
                order_by = metric)
    
    # plotting
    data %>%
      ggplot() + geom_bar(aes(x = reorder(fimanager, metric),
                              y = metric),
                          stat = "identity") +
      
      {
        if (input$metric3 == "number_of_sales")
          geom_label(aes(
            x = fimanager,
            y = metric,
            label = paste0(fimanager, "\n", round(metric, digits = 0))
          ),
          size = 3)
        
        else
          geom_label(
            aes(
              x = fimanager,
              y = metric,
              label = paste0(fimanager, "\n$", scales::comma(round(metric, digits = 0)))
            ),
            size = 3)
      } +
      # geom_label(aes(x = salesman,
      #                y = get(input$metric3),
      #                label = paste0(salesman, "\n", scales::comma(round(get(input$metric3), digits = 0)))),
      #            size = 3) +
      
      labs(y = "",
           x = "") +
      
      scale_y_continuous(expand = expansion(mult = c(-0.3, 0.1)),
                         breaks = integer_breaks(),
                         labels = comma) +
      
      theme(axis.text.x = element_blank(),
            axis.ticks.x = element_blank())
  })
  

}
