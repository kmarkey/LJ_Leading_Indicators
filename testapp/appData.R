# set app options

options(dplyr.summarise.inform = FALSE)

tags$style(type="text/css",
           ".shiny-output-error { visibility: hidden; }",
           ".shiny-output-error:before { visibility: hidden; }"
)

# tags$style(type = "text/css")

## need to read in json of app options, including raw KDA, prediction and imp data, lag number, 


# runtime app data
KDAc <- read_csv("data/KDAc.csv", show_col_types = FALSE)

# generated on
today <- Sys.Date()

# last month
lmonth <-
  floor_date(floor_date(today, unit = "month") - 1, unit = "month")

# bounds of 2nd to last month on record
nmonth <-
  floor_date(floor_date(max(KDAc$date), unit = "month") - 1, unit = "month")
nomonth <- ceiling_date(nmonth, unit = "month") - 1

# bounds of last full month on record
pmonth <- nomonth + 1
pqmonth <- ceiling_date(pmonth, unit = "month") - 1

maxdate <- max(KDAc$date)
# report would be made on the 1st of
repon <- pqmonth + 1

# report is for the month of (last month)
repfor <- paste0(month(pqmonth, label = TRUE, abbr = FALSE), ", ", year(pqmonth))

integer_breaks <- function(n = 5, ...) {
  fxn <- function(x) {
    breaks <- floor(pretty(x, n, ...))
    names(breaks) <- attr(breaks, "labels")
    breaks
  }
  return(fxn)
}

# month selector
month_choices <- unique(paste0(month(KDAc$date, abbr = FALSE, label = TRUE), ", ", year(KDAc$date)))

selected_month <- paste0(month(pqmonth, abbr = FALSE, label = TRUE), ", ", year(pqmonth))

month_bounds <- function(string) {
  # get current and previous month bounds from selected month
  start <- lubridate::mdy(
    sub(",", "/1/,", string))
  end <- ceiling_date(start, unit = "month") - 1

  return(c(start, end))
}

##################### table #############################

#read in indicidual files
cf <- read_csv("data/snapshots/corr_frame.csv",
               col_names = c("name", "Correlation"),
               skip = 1,
               col_types = c("cd"))

l <- read_csv("data/snapshots/l-imp.csv",
              col_names = c("idx", "LASSO", "name"),
              skip = 1,
              col_types = c("idc"))

t <- read_csv("data/snapshots/t-imp.csv",
              col_names = c("idx", "Decision Tree", "name"),
              skip = 1,
              col_types = c("idc"))

r <- read_csv("data/snapshots/r-imp.csv",
              col_names = c("idx", "Random Forest", "name"),
              skip = 1,
              col_types = c("idc"))

g <- read_csv("data/snapshots/g-imp.csv",
              col_names = c("idx", "GRU", "name"),
              skip = 1,
              col_types = c("idc"))

m <- read_csv("data/snapshots/m-imp.csv",
              col_names = c("idx", "LSTM", "name"),
              skip = 1,
              col_types = c("idc"))

# join all
coyote <- left_join(cf, l, by = "name") %>%
  left_join(t, by = "name") %>%
  left_join(r, by = "name") %>%
  left_join(g, by = "name") %>%
  left_join(m, by = "name") %>%
  dplyr::select(-starts_with("idx")) %>%

  # split out name to root and lag
  separate(col = name,
           into = c("key", "lag"),
           sep = "_lag") %>%

  mutate(root = sub("_v$", "", key),
         lag = as.numeric(lag))

########################### info dfs ###########################################
# read in json  files
library(rjson)

stock_info <- fromJSON(file = "data/stocks_info.json")

fred_info <- fromJSON(file = "data/fred_info.json")

trend_info <- fromJSON(file = "data/trends_info.json")

# parse Json fun
get_info <- function(data) {
  
  df <- data.frame()
  
  for (i in names(data)){
    
    for (j in data[i]) {
      r <- c(key = i, unlist(j))
    }
    df <- rbind(df, r)
  }
  
  names(df) <- c("key", names(data[[1]]))
  
  return(df)
}

# join files into info df
info_df <- rbind(get_info(stock_info),
                 get_info(fred_info),
                 get_info(trend_info)) %>%
  dplyr::summarise(name, key, category, updated, `citation`, link)

# join roots and amend names with volume
complete_info <- left_join(coyote, info_df, by = c("root" = "key")) %>%
  mutate(name = ifelse(str_detect(key, "_v$"), str_c(name, " Volume"), name))
complete_info

################################# predictions ##################################
file_list <- list.files("data/snapshots", pattern = "^[a-z].csv", full.names = TRUE)

new_colnames <- c("idx" = "...1", 
                  "actual" = "actual", 
                  "group" = "group", 
                  "ARIMA" = "pred.x", 
                  "GRU" = "pred.y", 
                  "LASSO" = "pred.x.x", 
                  "LSTM" = "pred.y.y", 
                  "Random Forest" = "pred.x.x.x", 
                  "Decision Tree" = "pred.y.y.y")

brot <-  purrr::map(file_list, read_csv, show_col_types = FALSE) %>%
  # purrr::map_dfc(file_list, read_csv)
  purrr::reduce(dplyr::left_join,
                by = c("...1", "actual", "group"),
                copy = FALSE) %>%
  dplyr::rename(all_of(new_colnames)) %>%
  relocate(idx, actual, group)
  
  # reorder and pivot cols?

# add in best lag and usage per model here