# runtime app data
KDAc <- read_csv("../data/sour/KDAc.csv", show_col_types = FALSE)

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
