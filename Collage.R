#! /usr/bin/Rscript

library(dplyr)
library(tidyr)
library(readr)
library(logger)
library(here)
library(tibble)
library(stringr)
library(lubridate)

source("process-functions.R")

here()

# parse args
cargs <- commandArgs(trailingOnly = TRUE)

# cargs to env
parmesean(cargs)

# ============================ make logfile ====================================
log_setup()

log_info("Running collage")


# log_info("Preparing data for {param_list[monthfile]} to estimate {param_list[targetvar]} for the next {ahead} months")

#================================ read in misc =================================
if (!exists("blank_m")) {
  blank_m <- read_csv("./keys/blank_m.csv", show_col_types = FALSE)
  log_trace("Reading in blank_m")
}

if (!exists("wolf")) {
  wolf <- read_csv("./data/in/wolf.csv")
  log_trace("Reading wolf")
}

#=================================== fred ======================================

if (!exists("fred")) {
  temp <- read_csv("data/in/fred.csv", 
                   col_types = list(date = col_date(format = "%Y-%m-%d"),
                                    .default = col_double()))
  
  fred <- temp %>%
    trim_it("fred") %>%
    lag_it()
  
  log_trace("Reading in FRED data")

}

exam(fred)
#============================== stocks =========================================

if (!exists("stocks")) {
  temp <- read_csv("data/in/stocks.csv", 
                   col_types = list(date = col_date(format = "%Y-%m-%d"),
                                    .default = col_double()))

stocks <- temp %>%
  trim_it("stocks") %>%
  lag_it()

log_trace("Reading stock data")

}


exam(stocks)
#=============================== google trends =================================

if (!exists("trends")) {
  temp <- read_csv("data/in/trends.csv", 
                   col_types = list(date = col_date(format = "%Y-%m-%d"),
                                    .default = col_double()))
  
  trends <- temp %>%
    trim_it("trends") %>% # arranges high to low
    lag_it()
  
  log_trace("Reading Google Trends data")
  
}

exam(trends)
#=============================== binary ========================================

bin <- cbind(bin = rep(c(0, 1), length.out = nrow(blank_m)), blank_m)

log_info("created bin")
exam(bin)
#============================== t - 1 ==========================================
log_info("read auto")
auto <- tibble(auto = c(rnorm(13, 
                              mean(pull(wolf, targetvar), na.rm = TRUE), 
                              sd(pull(wolf, targetvar), na.rm = TRUE)), 
                        lag(pull(wolf, targetvar), 1)[-1]), 
               date = blank_m$date)

exam(auto)
#=============================== website views + users =========================
# downloaded right now

if (!exists("website")) {
  website <- read_csv("./data/in/website.csv", skip = 5, show_col_types = FALSE)
  
  website <- website %>%
    dplyr::transmute(date = as.Date("2013-04-01") + months(as.numeric(`Month Index`), abbreviate = FALSE),
                     new_users = `New Users`,
                     session_dur = as.numeric(`Avg. Session Duration`)/60) %>%# time in minutes
    trim_it("website") %>%
    
    lag_it()
  
  log_info("reading web")
  
}

exam(website)
# finished with web
#================================= appointments? ===============================




#=============================== joins =========================================
log_trace("Joining features by month")

scaling <- function(x) { # normalization function, do later
  return((x - min(x, na.rm = T))/(max(x,  na.rm = T) - min(x, na.rm = T)))
}

complete_dirty <- dplyr::select(wolf, date, !!targetvar) %>%
  
  # econ
  left_join(fred, by = "date") %>%
  
  # stocks
  left_join(stocks, by = "date") %>%
  
  # google results
  left_join(trends, by = "date") %>%
  
  # leejohnson.com page views
  # left_join(website, by = "date") %>%
  
  # random binary
  left_join(bin, by = "date") %>%
  
  # add mnum
  dplyr::mutate(m_num = as.numeric(month(date))) %>%
  ###############
  arrange(date) %>%
  ungroup() %>%
  dplyr::select(-date)

log_info("complete complete")
# mutate(across(is.numeric, ~ scaling(.))) # apply later

log_info("Compiled {(ncol(complete_dirty) - 2)/5} potential features")

if(sum(is.na(complete_dirty)) != 0) {
  log_warn("{sum(is.na(complete_dirty))} missing values in feature data")
}

#write
write_csv(complete_dirty, "./data/out/complete.csv")
#============================ wide cor filter ==================================

log_trace("Doing correlations")

complete_cor <- complete_dirty %>%
  cor(use = "pairwise.complete.obs")

# select features in features dict by month lagged
enumerate <- function(x, threshold) {
  under <- 0:threshold
  out <- str_c(x, under)
  return(out)
}

# select one lag per source that is above ahead and cor cutoff
feature_dict <- as.data.frame(complete_cor) %>%
  
  dplyr::filter(!!targetvar >= cor_max | !!targetvar <= -cor_max, !!targetvar != 1) %>% # correlation cutoff
  
  dplyr::select(!!targetvar) %>% # get correlation of all cols to n
  
  rownames_to_column("name") %>%
  
  dplyr::filter(
    as.numeric(str_remove(name, ".*_lag")) >= ahead | is.na(as.numeric(str_remove(name, ".*_lag")))) %>%
  
  group_by(str_replace(name, "_lag.*", "")) %>% # group bysource
  
  slice_max(get(targetvar)) %>% # find features with highest cor to n
  
  ungroup() %>%
  
  dplyr::pull(name) # name to vector

log_info("Cooking down:
         Slicing at cor = {cor_max} and picking {length(feature_dict)} best feature names
         Ahead {ahead} months")

#============================== prevent flow backup ============================
# cutting horizontally
dam <- names(complete_dirty)[which(is.na(complete_dirty[nrow(complete_dirty),]))]

if (length(dam) > 0) {
  log_warn("{dam} is blocking the pipe! It should be considered an invalid source.")
}

#================================ set bloating =================================
if (bloat == FALSE) {
  
  blort <- colSums(sapply(complete_dirty, is.na))
  
  blort_names <- names(blort[blort <= round(mean(blort))])
  
  features <- dplyr::select(complete_dirty, !!targetvar, all_of(feature_dict), -all_of(dam)) %>%
    dplyr::select(all_of(any_of(blort_names))) %>%
    tibble::rowid_to_column("month") %>%
    na.omit()
} else {
  
  features <- dplyr::select(complete_dirty, !!targetvar, all_of(feature_dict), -all_of(dam)) %>% # correlation
    tibble::rowid_to_column("month") %>%
    na.omit()
}

log_info("Boiled off {ncol(complete_dirty) - ncol(features)} columns and {nrow(complete_dirty) - nrow(features)} rows")

# write up supp for bin and month  (probably not used)

m_num_supp <- (features$m_num[nrow(features)] + 1):(features$m_num[nrow(features)] + 3)

write_csv(
  tibble(month = (max(features$month) + 1):(max(features$month) + ahead), 
         bin = bin$bin[(nrow(bin) - (ahead - 1)):nrow(bin)],
         m_num = ifelse(m_num_supp > 12, m_num_supp - 12, m_num_supp)),
          
          "data/out/suppl.csv")
#==================================== write out ================================
log_info("{ncol(features) - 1} features saved to features.csv, length {nrow(features)}") # -n and month

write_csv(features, "data/out/features.csv")

log_success("End collage.R")
