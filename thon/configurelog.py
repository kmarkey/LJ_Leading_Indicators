import logging

# logging.basicConfig(level=logging.DEBUG)
# logging.debug('This will get logged')

def get_logger(logfile, filelevel = logging.INFO):
  
    fmt = '%(levelname)s [%(asctime)s] %(message)s'
    datefmt = '%Y-%m-%d %H:%M:%S'
    
    # create logger
    logging.basicConfig(format = fmt, level = filelevel, datefmt = datefmt)
    
    logger = logging.getLogger(__name__)
    
    # create file handlers
    fh = logging.FileHandler(logfile)
    fh.setLevel(filelevel)

    ch = logging.StreamHandler()

    # create formatter
    formatter = logging.Formatter(fmt = '%(levelname)s [%(asctime)s] %(message)s', datefmt = '%Y-%m-%d %H:%M:%S')
    
    # apply formatting
    # fh.setFormatter(formatter)
    # ch.setFormatter(formatter)
    
    logger.addHandler(fh)
    logger.addHandler(ch)
    # logger.setLevel(filelevel)
    
    return logger

def log_info(msg):
  py_log.info(msg)
  
def log_debug(msg):
  py_log.debug(msg)
  
def log_error(msg):
  py_log.error(msg)
  
def log_exception(msg):
  py_log.exception(msg)


  
  
