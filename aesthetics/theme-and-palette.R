# colors, functions for plotting
library(ggplot2)


pal <-
  c("#f6aa1c",
             "#08415c",
             "#6b818c",
             "#eee5e9",
             "#ba7ba1",
             "#c28cae",
             "#a52a2a")
             
blue <- "#114482"
lightblue <- "#146ff8"
llightblue <- "#AFCFFF"
red <- "#a52a2a"
white <- "#FBFFF1"
yellow <- "#F6AA1C"
green <- "#588157"
              
ljtheme <- function() {
  theme_minimal() %+replace%
    theme(
      panel.grid.major = element_line(
        linetype = "solid",
        color = llightblue,
        linewidth = 0.1
      ),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = white),
      #light
      panel.border = element_rect(
        color = lightblue,
        fill = NA,
        linetype = "solid",
        linewidth = 2
      ),
      legend.background = element_rect(
        fill = white,
        color = lightblue,
        linewidth = 1
      ),
      # legend
      legend.text = element_text(color = blue),
      legend.title = element_text(face = "bold.italic", color = blue),
      legend.position = "bottom",
      legend.key = element_rect(fill = white),
      
      
      strip.text.x = element_text(
        size = 16,
        color = white,
        face = "bold.italic"
      ),
      strip.text.y = element_text(
        size = 16,
        color = white,
        face = "bold.italic"
      ),
      text = element_text(color = white),
      axis.title = element_text(
        face = "italic",
        size = 16,
        color = white
      ),
      axis.text = element_text(color = white, size = 14),
      axis.ticks = element_line(
        color = white,
        linewidth = .5,
        lineend = "butt"
      ),
      axis.ticks.length = unit(.1, "cm"),
      plot.title = element_text(
        face = "bold",
        # labels
        color = white,
        size = 20,
        hjust = 0,
        vjust = 1.5
      ),
      plot.subtitle = element_text(
        color = white,
        hjust = 0,
        vjust = 1.5,
        face = "italic"
      ),
      plot.caption = element_text(color = white, face = "bold"),
      plot.background = element_rect(fill = blue)
    )
}

library(elementalist) # devtools::install_github("teunbrand/elementalist")

webtheme <- function(){
  theme(
    # legend.background = element_rect_round(radius = unit(0.2, "snpc")),
    # legend.key = element_rect_round(radius = unit(0.4, "snpc")),
    panel.background = element_blank(),
    # strip.background = element_rect_round(radius = unit(0.1, "pt")),
    plot.background  = element_blank(), 
    axis.ticks.x = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_line(colour = "black"),
    
    
    
  )
}

# A function factory for getting integer y-axis values.
integer_breaks <- function(n = 5, ...) {
  fxn <- function(x) {
    breaks <- floor(pretty(x, n, ...))
    names(breaks) <- attr(breaks, "labels")
    breaks
  }
  return(fxn)
}