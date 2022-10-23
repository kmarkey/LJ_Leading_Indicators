library(Quandl)
library(dplyr)
library(tidyr)
library(readr)
library(logger)
library(here)
library(tibble)

setwd(here())
here()
# set correlation cutoff
cor_max <- 0.20

# set lead time in months (3)
ahead <- 3

# month file being used
monthfile <- "month.csv"

# variable(s) within month to select
targetvar <- "n"

param_list <- list(month_n.csv = "new cars", month_u.csv = "used cars", month_pre.csv = "pre-COVID",
                   month_post.csv = "post-COVID", month_all.csv = "all months", n = "total sales", 
                   tgp = "total gross profit", cp = "cash_price")

# ============================ make temp logfile ==============================-
my_logfile <- paste0("./logs/my_log_", Sys.Date(), ".txt")

file.create(my_logfile)

log_appender(appender_tee(my_logfile))


log_info("{timestamp()}")

log_info("Preparing data for {param_list[monthfile]} to estimate {param_list[targetvar]} for the next {ahead} months")


log_info("Correlation cutoff set to {cor_max} and lead time set to {ahead} months")

# correlation function

exam <- function(data, threshold = cor_max, interval = "month", targetvar = targetvar) {
    data <- left_join(month, data, by = "date") %>%
      dplyr::select(-date)
    #correlation matrix
    rac <- as.data.frame(
      cor(data, use = "pairwise.complete.obs"))
    out <- rac %>%
      dplyr::select(n) %>%
      filter(n != 1) %>%
      arrange(desc(abs(n)))
    pass <- filter(out, abs(n) >= threshold)
    print(pass)
}


lag_it <- function(data) {
  data %>%
    dplyr::mutate(across(where(is.numeric), 
                         .fns = list(lag0 = ~.,
                                     lag3 = ~ lag(., 3), 
                                     lag6 = ~ lag(., 6),
                                     lag9 = ~ lag(., 9),
                                     lag12 = ~ lag(., 12)),
                         .names = "{.col}_{.fn}"), 
                  .keep = "unused")
}

cargs <- commandArgs()
source("Transform.R")
source("Digest.R")
source("Scrape.R")

#=================================== fred ======================================
log_trace("Fetching FRED data")

fred <- read_csv("data/in/fred.csv")

fred <- fred %>%
  right_join(blank_m, by = "date") %>% # arranges high to low and filters
  lag_it()

exam(fred, cor_max)
#============================== stocks =========================================
log_trace("Fetching stock data")

stocks <- read_csv("data/in/stocks.csv")

stocks <- blank_m %>%
  left_join(stocks, by = "date") %>%
  lag_it()

exam(stocks, cor_max)
#=============================== google trends =================================
log_trace("Fetching Google Trends data")

trends <- read_csv("data/in/trends.csv")

trends <- blank_m %>%
  left_join(trends, by = "date") %>% # arranges high to low
  lag_it()

exam(trends)
#=============================== Quandl ========================================
log_trace("Fetching Quandl data")

quandl <- read_csv("data/in/quandl.csv")

quandl <- blank_m %>%
  left_join(quandl, by = "date") %>% # arranges high to low
  lag_it()

exam(quandl)
######## add appts here? #########

#=============================== random ========================================
# random <- tibble(random = runif(n = nrow(blank_m), 1, 10),
#                  date = blank_m$date)

bin <- cbind(bin = rep(c(1, 0, 0), length.out = nrow(blank_m)), blank_m)

exam(bin)

#============================== t - 1 ==========================================

auto <- tibble(auto = c(rnorm(13, 
                              mean(pull(month, targetvar), na.rm = TRUE), 
                              sd(pull(month, targetvar), na.rm = TRUE)), 
                        lag(pull(month, targetvar), 1)[-1]), 
               date = blank_m$date)

exam(auto)
#=============================== website views =================================

pageviews <- read_csv("data/in/analytics/pageviews.csv", skip = 5)

pageviews <- pageviews %>%
  dplyr::mutate(date = min(blank_m$date) + months(as.numeric(`Month Index`))) %>%
  right_join(blank_m, by = "date") %>%
  summarise(date, pageviews = Pageviews) %>%
  lag_it()

exam(pageviews)
#================================= new website users ===========================

new_users <- read_csv("data/in/analytics/new_users.csv", skip = 5)

new_users <- new_users %>%
  dplyr::mutate(date = min(blank_m$date) + months(as.numeric(`Month Index`))) %>%
  right_join(blank_m, by = "date") %>%
  summarise(date, new_users = `New Users`) %>%
  lag_it()

exam(new_users)
#=============================== joins =========================================
log_info("Joining features by month")

scaling <- function(x) { # normalization function
  return((x - min(x))/(max(x) - min(x)))
}

complete_dirty <- dplyr::select(month, date, n) %>%
  
  # econ
  left_join(fred, by = "date") %>%
  
  # stocks
  left_join(stocks, by = "date") %>%
  
  # google results
  left_join(trends, by = "date") %>%
  
  left_join(quandl, by = "date") %>%
  
  # random feature
  # left_join(random, by = "date") %>%
  
  # autocorrelation %>%
  left_join(auto, by = "date") %>%
  
  # leejohnson.com page views
  left_join(pageviews, by = "date") %>%
  
  # new website users
  left_join(new_users, by = "date") %>%
  
  # random binary
  left_join(bin, by = "date") %>%
  
  # add more later
  #######################################
  arrange(date) %>%
  dplyr::select(-date)
# mutate(across(is.numeric, ~ scaling(.))) # apply dynamically

if(sum(is.na(complete_dirty)) != 0) {
  log_warn("Missing values in feature data")
}

write_csv(complete_dirty, "data/out/complete.csv")
#============================ wide filter to cor ===============================

log_info("Filtering for correlation = {cor_max} and lead = {ahead} months")

# change date to month key col
complete_cor <- complete_dirty %>%
  cor()

# select features in features dict by month lagged
enumerate <- function(x, threshold) {
  under <- 0:threshold
  out <- str_c(x, under)
  return(out)
}

# select for correlation cutoff
# feature_dict <- complete_cor[complete_cor['n',] >= cor_max | complete_cor['n',] <= -cor_max, 'n']

# select one lag per source that is above ahead and cor cutoff
feature_dict <- as.data.frame(complete_cor) %>%
  dplyr::filter(n >= cor_max | n <= -cor_max, n != 1) %>% # correlation cutoff
  dplyr::select(n) %>% # get correlation of all cols to n
  rownames_to_column("name") %>%
  dplyr::filter(
    as.numeric(str_remove(name, ".*_lag")) >= ahead | is.na(as.numeric(str_remove(name, ".*_lag")))) %>%
  group_by(str_replace(name, "_lag.*", "")) %>% # group by source
  slice_max(n) %>% # find features with highest cor to n
  ungroup() %>%
  dplyr::pull(name) # name to vector

# send best lag value
features <- dplyr::select(complete_dirty, n, all_of(feature_dict)) %>% # correlation
  tibble::rowid_to_column("month")

write_csv(tibble(month = (max(features$month) + 1):(max(features$month) + ahead), 
                 bin = bin$bin[(nrow(bin) - (ahead - 1)):nrow(bin)]),
          "data/out/suppl.csv")

#==================================== write out ================================
log_info("{ncol(features) - 2} features saved to features.csv") # -n and month
write_csv(features, "data/out/features.csv")

log_appender()
