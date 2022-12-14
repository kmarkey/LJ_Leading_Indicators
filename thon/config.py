import logging
import os
from datetime import date, datetime as dt 


def config_logger(logfile = "./logs/my_log_" + str(date.today()) + ".log", filelevel = logging.INFO):
  
    fmt = '%(levelname)s [%(asctime)s] %(message)s'
    datefmt = '%Y-%m-%d %H:%M:%S'
    
    # create formatter
    formatter = logging.Formatter(fmt = fmt, datefmt = datefmt)
    
    # create logger
    logger = logging.getLogger(__name__)
    
    # create file handlers
    try:
        
        fh = logging.FileHandler(logfile)
        fh.setFormatter(formatter)
        
    except:
        
        f = open(logfile, "w+")
        fh = logging.FileHandler(logfile)
        fh.setFormatter(formatter)
        
    ch = logging.StreamHandler()
    ch.setFormatter(formatter)

    # add  handlers
    logger.handlers.clear()
    logger.addHandler(ch)
    logger.addHandler(fh)
    
    # set level
    logger.setLevel(filelevel)

    return logger

def close_logger(_logger):
    
    return _logger
    # for h in _logger.handlers:
    #     _logger.removeHandler(h)
    #     h.close()

def config_rload(script, arglist):
  load = ["Rscript", "--vanilla", script, "--args"]
  load.extend(arglist)
  
  return(load)
