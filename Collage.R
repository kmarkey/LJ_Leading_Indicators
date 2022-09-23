library(Quandl)
library(dplyr)
library(tidyr)
library(readr)

# correlation function

exam <- function(data, threshold = 0.25, interval = "month") {
  if (interval == 'month'){
    data <- left_join(month, data, by = "date") %>%
      dplyr::select(-date, -tgp_a, -cp_a)
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
}

#=================================== fred ======================================

fred <- read_csv("data/in/fred.csv")

fred <- fred %>%
  right_join(blank_m, by = "date") %>% # arranges high to low
  dplyr::mutate(across(is.numeric, .fns = list(raw = ~.,
                                               lag1 = ~ lag(., 1), 
                                               lag2 = ~ lag(., 2),
                                               lag3 = ~ lag(., 3),
                                               lag6 = ~ lag(., 6),
                                               lag12 = ~ lag(., 12)),
                       .names = "{.col}_{.fn}"), 
                .keep = "unused")

exam(fred, cor_max)

#============================== stocks =========================================
stocks <- read_csv("data/in/stocks.csv")

stocks <- blank_m %>%
  left_join(stocks, by = "date") %>%
  dplyr::mutate(across(is.numeric, .fns = list(raw = ~.,
                                               lag1 = ~ lag(., 1), 
                                               lag2 = ~ lag(., 2),
                                               lag3 = ~ lag(., 3),
                                               lag6 = ~ lag(., 6),
                                               lag12 = ~ lag(., 12)),
                       .names = "{.col}_{.fn}"), 
                .keep = "unused")

exam(stocks, cor_max)

#=============================== google trends =================================
trends <- read_csv("data/in/trends.csv")

trends <- blank_m %>%
  left_join(trends, by = "date") %>% # arranges high to low
  dplyr::mutate(across(is.numeric, .fns = list(raw = ~.,
                                               lag1 = ~ lag(., 1), 
                                               lag2 = ~ lag(., 2),
                                               lag3 = ~ lag(., 3),
                                               lag6 = ~ lag(., 6),
                                               lag12 = ~ lag(., 12)),
                       .names = "{.col}_{.fn}"), 
                .keep = "unused")

exam(trends)

#=============================== Quandl ========================================
quandl <- read_csv("data/in/quandl.csv")

quandl <- blank_m %>%
  left_join(quandl, by = "date") %>% # arranges high to low
  dplyr::mutate(across(is.numeric, .fns = list(raw = ~.,
                                               lag1 = ~ lag(., 1), 
                                               lag2 = ~ lag(., 2),
                                               lag3 = ~ lag(., 3),
                                               lag6 = ~ lag(., 6),
                                               lag12 = ~ lag(., 12)),
                       .names = "{.col}_{.fn}"), 
                .keep = "unused")

exam(quandl)


######## add appts here? #########

#=============================== random ========================================
random <- tibble(random = runif(n = nrow(blank_m), 1, 10),
                 date = blank_m$date)

exam(random)

#============================== t - 1 ===========================================

auto <- tibble(auto = c(rnorm(13, month$n, sd(month$n)), lag(month$n, 1)[-1]),
               date = blank_m$date)

exam(auto)
#=============================== joins =========================================

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
  left_join(random, by = "date") %>%
  
  # autocorrelation %>%
  left_join(auto, by = "date") %>%
  
  
  # add more later
  #######################################
  tibble::rowid_to_column("month") %>%
  dplyr::select(-date)
# mutate(across(is.numeric, ~ scaling(.))) # apply active later

#============================ wide filter to cor ===============================
write_csv(complete_dirty, "data/out/complete.csv")

# change date to month key col
complete_cor <- complete_dirty %>%
  cor()

# select for co  >= 0.25
feature_dict <- complete_cor[complete_cor['n',] >= cor_max | complete_cor['n',] <= -cor_max, 'n']


# select features in features dict
features <- dplyr::select(complete_dirty, all_of(names(feature_dict))) %>%
  dplyr::select(-ends_with(c("_raw", "_lag1", "_lag2")))
feature_dict

#==================================== write out ================================
write_csv(features, "data/out/features.csv")
