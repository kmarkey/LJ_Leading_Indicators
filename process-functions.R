#! /usr/bin/Rscript

# functions
# all environments set to be inherited

# get command args in named list
parmesean <- function(cargs) {
  
  if (length(t) > 0) {
    
    log_info("{length(t)} Command args recieved")
    
  } else {
    
    log_fatal("No command args recieved")
    
    return("Please start some arguments")
  }
  
  t <- strsplit(cargs, " ")
  
  # remove --args from args
  plist <- t[t != "--args"]
  # extract names
  names(plist) <- sapply(plist,"[[", 1)
  
  plist <- sapply(plist,"[[", 2)
  
  # assign with correct data type into env
  to_env <- function(name, type) {
      if (name %in% names(plist)) {
          assign(name, type(plist[[name]]), inherits = TRUE)
      
      } else {
          log_warn("No argument specified for {name}")
      }
    
    
  }
  
  to_env("cor_max", as.numeric)
  to_env("ahead", as.numeric)
  to_env("train_set", as.character)
  to_env("targetvar", as.character)
  to_env("bloat", as.logical)
  to_env("newdata", as.character)
}

# remove character class and change parsing
pear <- function(x) {
  x <- gsub("[()\\s,]", "", x)
  x <- as.numeric(x)
}

clean_kda <- function(data) {
  
  old_names <- names(data)
  
  new_names <- c("date", "dealnum", "vstock", "caryear", "make",
                 "model", "nu", "front_gross_profit", "back_gross_profit",
                 "total_gross_profit", "cash_price", "pl", "sale_type",
                 "salesman", "salesmanager", "fimanager")
  
  if (length(old_names) == length(new_names)) {
    data <- rename_at(data, old_names, ~ new_names)
    
  } else {
    log_warn("Cannot change column names")
  }
  
  log_trace("Juggling numeric columns")
  
  # clean all and make numeric
  data <- mutate(data, across(c(front_gross_profit,
                                back_gross_profit,
                                total_gross_profit,
                                cash_price), 
                              pear),
                 date = as.Date(date, format = "%m/%d/%Y")) # change date
  
  #======================- create model year variable ============================
  # highest possible model year = current year + 1, assuming age < 100
  max_model_year <- as.numeric(substr(year(Sys.Date()) + 1, 3, 4))
  
  data <- data %>%
    
    mutate(caryear = as.numeric(
      ifelse(str_length(caryear) == 1, str_c("200", caryear), 
             ifelse(str_length(caryear) == 2 & caryear > max_model_year, str_c("19", caryear),
                    str_c("20", caryear))))
    ) %>%
    mutate(across(where(is.numeric), ~replace_na(., 0))) %>%
    arrange(date)
  
}

# eval with wolf
exam <- function(data, threshold = cor_max) {
  if (!exists("wolf", inherits = TRUE)) {
    log_warn("wolf not found")
  }
  
  if (!exists("targetvar", inherits = TRUE)) {
    log_warn("targetvar not found for examination")
    
    return("Error: targetvar not found")
  }
  out <- as.data.frame(
    cor(
      # must have wolf in env
      left_join(wolf, data, by = "date") %>%
        ungroup() %>%
        dplyr::select(-date), 
      
      use = "pairwise.complete.obs")) %>%
    
    dplyr::select(!!targetvar) %>%
    
    dplyr::filter(abs(get(targetvar)) >= threshold & get(targetvar) != 1) %>%
    
    arrange(desc(abs(get(targetvar))))
  
  return(out)
}

# lag dataset
lag_it <- function(data) {
  data %>%
    arrange(date) %>%
    dplyr::mutate(across(where(is.numeric), 
                         .fns = list(lag0 = ~.,
                                     lag3 = ~ lag(., 3), 
                                     lag6 = ~ lag(., 6),
                                     lag9 = ~ lag(., 9),
                                     lag12 = ~ lag(., 12)),
                         .names = "{.col}_{.fn}"), 
                  .keep = "unused")
}

trim_it <- function(data, name, ruler = blank_m) {
  # https://community.rstudio.com/t/using-deparse-substitute-expression-with-pipe/137595
  if (!exists("blank_m", inherits = TRUE)) {
    
    log_warn("blank_m not found")
  }

  out <- data %>%
    right_join(ruler, by = "date")
  
  log_info("{sum(is.na(out))} missing values in {name}")
  
  return(out)
}

log_setup <- function() {
  library(logger)
  my_logfile <- paste0("./logs/my_log_", Sys.Date(), ".log")
  
  if (file.exists(my_logfile)) {
    log_appender(appender_tee(my_logfile))
    
  } else {
    file.create(my_logfile)
    log_appender(appender_tee(my_logfile))
    
  }
  print(paste0("Log created at ", my_logfile))
}
