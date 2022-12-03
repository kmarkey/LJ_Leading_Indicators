import logging

# logging.basicConfig(level=logging.DEBUG)
# logging.debug('This will get logged')

def config_logger(logfile, filelevel = logging.INFO):
  
    fmt = '%(levelname)s [%(asctime)s] %(message)s'
    datefmt = '%Y-%m-%d %H:%M:%S'
    
    # create formatter
    formatter = logging.Formatter(fmt = fmt, datefmt = datefmt)
    
    # create logger
    logger = logging.getLogger(__name__)
    
    # create file handlers
    fh = logging.FileHandler(logfile)
    fh.setFormatter(formatter)

    ch = logging.StreamHandler()
    ch.setFormatter(formatter)

    # add  handlers
    logger.handlers.clear()
    logger.addHandler(fh)
    logger.addHandler(ch)
    
    # set level
    logger.setLevel(filelevel)

    return logger

def config_rload(script, arglist):
  load = ["Rscript", "--vanilla", script, "--args"]
  load.extend(arglist)
  
  return(load)
