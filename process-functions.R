#! /usr/bin/Rscript

# functions
# all environments set to be inherited

# get command args in named list
parmesean <- function(cargs) {
  if (length(cargs) == 6) {
    log_trace("6 Command args recieved")
    
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
  assign("cor_max", as.numeric(plist[["cor_max"]]), inherits = TRUE)
  assign("ahead", as.numeric(plist[["ahead"]]), inherits = TRUE)
  assign("train_set", as.character(plist[["train_set"]]), inherits = TRUE)
  assign("targetvar", as.character(plist[["targetvar"]]), inherits = TRUE)
  assign("bloat", as.logical(plist[["bloat"]]), inherits = TRUE)
}

# remove character class and change parsing
pear <- function(x) {
  x <- gsub("[()\\s,]", "", x)
  x <- as.numeric(x)
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
  
  print(out)
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
  my_logfile <- paste0("./logs/my_log_", Sys.Date(), ".log")
  if  (file.exists(my_logfile)) {
    log_appender(appender_tee(my_logfile))
  } else {
    file.create(my_logfile)
    log_appender(appender_tee(my_logfile))
  }
  print(paste0("Log created at ", my_logfile))
}
