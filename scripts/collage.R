#! /usr/bin/Rscript

library(dplyr)
library(tidyr)
library(readr)
library(logger)
library(here)
library(tibble)
library(stringr)
library(lubridate)

if(!exists("utilities_loaded")) source("./scripts/r_utilities.R")

log_setup()

# ============================ make logfile ====================================

log_info("Running collage")

#================================ read in walls =================================

if (!exists("blank_m")) {
    
    blank_m <- read_csv("./keys/blank_m.csv", show_col_types = FALSE)
    
    log_trace("Reading in blank_m")
    
    }

if (!exists("wolf")) {
    
    wolf <- read_csv("./data/in/wolf.csv")
      
    log_trace("Reading wolf")
    
    }
#============================== stocks =========================================

temp <- read_csv("./data/in/stocks.csv", 
                 
                 col_types = list(date = col_date(format = "%Y-%m-%d"),
                                  .default = col_double()))

stocks <- temp %>%
  
  trim_it("stocks")

log_trace("Reading stock data")


log_trace("{
  round(
    nrow(exam(stocks)) / ncol(stocks), 2) * 100}% pass from stocks.csv"
         )
#=================================== fred ======================================

temp <- read_csv("./data/in/fred.csv",
                 
                 col_types = list(date = col_date(format = "%Y-%m-%d"),
                                  .default = col_double()))

fred <- temp %>%
    
    trim_it("fred")

log_trace("Reading in FRED data")


log_trace("{
  round(nrow(exam(fred)) / ncol(fred), 2) * 100}% pass from fred.csv"
)

#=============================== google trends =================================

temp <- read_csv("./data/in/trends.csv", 
                 
                 col_types = list(date = col_date(format = "%Y-%m-%d"),
                                  .default = col_double()))

trends <- temp %>%
    
    trim_it("trends")

log_trace("Reading Google Trends data")


log_trace("{
  round(nrow(exam(trends)) / ncol(trends), 2) * 100}% pass from trends.csv"
)

#=============================== supplemental data =============================
supp <- blank_m %>%
    
    transmute(date = date,
              month = month(date),
              quarter = quarter(date),
              year = year(date))

# added support for ahead > 3
supp_ext <- tibble(dum = rep(max(blank_m$date), ahead)) %>%
  
  dplyr::transmute(date = dum + months(row_number(dum)),
                month = month(date),
                quarter = quarter(date),
                year = year(date))

log_trace("Including all supplemental data")

#=============================== website views + users =========================
                          # downloaded right now  #
                          # changed to GA4        #
                          # working on update     #

# website <- read_csv("./data/in/website.csv", skip = 5, show_col_types = FALSE)
# 
# website <- website %>%
#     
#     dplyr::transmute(date = as.Date("2013-04-01") + months(as.numeric(`Month Index`), abbreviate = FALSE),
#                      new_users = `New Users`,
#                      session_dur = as.numeric(`Avg. Session Duration`)/60) %>% # time in minutes
#     
#     trim_it("website") %>%
#     
#     lag_it() %>%
  
    # if NA, to 0
#     replace(is.na(.), 0)

#================================= appointments? ===============================
                            # Get appt data  #
                            # From old login #
log_trace("Reading web data")


#=============================== joins =========================================
log_trace("Joining features by month")

scaling <- function(x) { # normalization function, but scale in python
    
    return((x - min(x, na.rm = T))/(max(x,  na.rm = T) - min(x, na.rm = T)))
    
}


complete_dirty <- dplyr::select(wolf, date, !!targetvar) %>%
    
    # econ
    left_join(stocks, by = "date") %>%
    
    # stocks
    left_join(fred, by = "date") %>%
    
    # google results
    left_join(trends, by = "date") %>%
    
    # webpage views
    # left_join(website, by = "date") %>%
    
    # seasonal data
    left_join(supp, by = "date") %>%
    
    arrange(date) %>%
      
    ungroup()

log_trace("Compiled {(ncol(complete_dirty) - 4)/5} potential features")

if(sum(is.na(complete_dirty)) != 0) {
    
    log_info("{sum(is.na(complete_dirty))} missing values in complete_dirty")
  
}
# =============================== correlation ==================================

log_trace("Doing correlations")

complete_cor <- complete_dirty %>%
    
    select(-date) %>%
    
    cor(use = "complete.obs")

library(car)

simpmod <- lm(n ~ ., data = complete_dirty %>% select(-date) %>% mutate(across(everything(), ~scaling(.))))

vif(simpmod)

complete_dirty
library(corrplot)

corrplot.mixed(complete_cor)
# save feature correlations
cor_frame <- complete_cor %>%
  as.data.frame() %>%
  select(n) %>%
  rownames_to_column("feature") %>%
  filter(n < 1.0)

# select one lag per source that is above ahead and corr cutoff
feature_dict <- as.data.frame(complete_cor) %>%
  
  dplyr::select(!!targetvar) %>% # get correlation of all cols to n
  
  dplyr::filter((!!targetvar >= cor_max | !!targetvar <= -cor_max) & !!targetvar != 1) %>% # correlation cutoff
  
  rownames_to_column("name") %>%
  
  # lag must be 3+ and keep seasonal (supplemental) vars
  dplyr::filter(
    as.numeric(stringr::str_remove(name, ".*_lag")) >= ahead | !grepl(".*_lag", name)) %>%
  
  dplyr::group_by(stringr::str_replace(name, "_lag.*", "")) %>% # group by source
  
  dplyr::slice_max(get(targetvar), n = 1) %>% # find features with highest cor to n
  
  dplyr::ungroup() %>%
  
  dplyr::pull(name) # name to vector

log_info("Cooking down: Slicing at cor = {cor_max} and picking {length(feature_dict) - 4} best feature names, ahead {ahead} months")
#============================== prevent backup =================================

# any NA's at the end of the df?
dam <- names(complete_dirty)[is.na(complete_dirty[nrow(complete_dirty),])]

if (length(dam) > 0) {
    
    log_warn("{dam} hasn't been retrieved! Maybe the source hasn't been updated yet. Also, check hooks.py")
    
    }

#======================== Remove impossible features ===========================

# Source roots of dammed names
damroots <- sub("_lag[0-9]{1-2}", "", dam)

# get total nas in each col
blort <- colSums(sapply(complete_dirty, is.na))

# get names with > 50% NAs
blort_names <- names(blort[blort <= mean(blort)])


features <- dplyr::select(complete_dirty, all_of(blort_names)) %>%
  
    dplyr::select(!!targetvar, any_of(feature_dict), -starts_with(damroots)) %>% # remove ineligible features
  
  na.omit()

log_info("Trimmed off {ncol(complete_dirty) - ncol(features)} columns and {nrow(complete_dirty) - nrow(features)} rows")

# write up supp for bin and month  (probably not used)

write_csv(cor_frame, "./data/out/corr_frame.csv")
write_csv(supp_ext, "./data/out/supp_ext.csv")
#==================================== write out ================================

write_csv(complete_dirty, "./data/out/complete.csv")

log_info("{ncol(features) - 1} features saved to features.csv, length {nrow(features)}") # -n and month

write_csv(features, "./data/out/features.csv")

log_success("End collage.R")

rm(stocks, fred, trends, complete_cor)
