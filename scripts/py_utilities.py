import logging
import os
import re
from datetime import date, datetime as dt 
import json

# sensetive to daily file name
def config_logger(logfile = "./logs/" + str(date.today()) + "/log.log", filelevel = logging.INFO):
  
    fmt = '%(levelname)s [%(asctime)s] %(message)s'
    datefmt = '%Y-%m-%d %H:%M:%S'
    
    # create formatter
    formatter = logging.Formatter(fmt = fmt, datefmt = datefmt)
    
    # create logger
    logger = logging.getLogger(__name__)
    
    # create file handlers
    try:
        
        fh = logging.FileHandler(logfile)
        
    except FileNotFoundError:
        
        mydir = logfile
        
        created = False
        
        while created == False:
            
            try:
                
                # make directory
                os.mkdir(mydir)
                
                # if success
                created = True
                
            except FileNotFoundError:
                
                mydir = "/".join(mydir.split("/")[:-1])
                
        fh = logging.FileHandler(logfile)
        
    # file handler 
    fh.setFormatter(formatter)
    
    # console handler
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


def get_newest_dir_py(path = "./logs/"):
  # get list of files
  filelist = [f for f in os.listdir(path = path) if re.match(r'[0-9]{4}-[0-9]{2}-[0-9]{2}', f)]
  
  return max(filelist)

def get_newest_file_py(path = "./logs/"):
  
  # match if date is anywhere in name
  filelist = [f for f in os.listdir(path = path) if re.match(r'.*[0-9]{4}-[0-9]{2}-[0-9]{2}.*', f)]
  
  return max(filelist)


def read_run_params_py():
  # read most recent file
  logdir = get_newest_dir_py()
  
  with open('./logs/' + logdir + '/params.log', 'r') as f:
    params = json.load(f)
    
  return params
