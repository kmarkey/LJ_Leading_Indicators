# pybrain
import subprocess
import os
import logging
from thon import scrape, configurelog
import datetime

os.chdir("C:\\Users\\keato\\Documents\\LocalRStudio\\LJ_Leading_Indicators\\")

# set feature correlation cutoff
cor_max = 0.20

# set lead time in months (3)
ahead = 3

# data subset being used
train_set = "all"

# variable(s) within month to select
targetvar = "n"

# favor wide over long feature data
bloat = False

arglist = ["cor_max {}".format(cor_max), "ahead {}".format(ahead), "train_set {}".format(train_set), 
"targetvar {}".format(targetvar), "bloat {}".format(bloat)]
#===============================================================================
stocklist = ["GM", "F", "TSLA", "AN", "MZDAY", "XOM", "TM", "LEA", "BWA", "VC", "GT", "NIO", "HMC", "RACE"]
fredpairs = {
    'unemp': 'UNRATE',
    'unempt5w': 'UEMPLT5',
    'unemp5tp14w': 'UEMP5TO14',
    'unemp15to26w': 'UEMP15T26',
    'unemp15ov':'UEMP15T26',
    'oilimport': 'IR10000',
    'ngspot': 'MHHNGSP',
    'hcpi': 'CUURA400SAH',
    'food': 'CUURA423SAF11',
    'sahmrule': 'SAHMREALTIME',
    'discount': 'TB3MS',
    'localrent': 'CUURA423SEHA',
    'durable': 'DGORDER',
    '10yinf': 'T10YIEM',
    'kwhcost': 'APUS49D72610',
    'sentiment': 'UMCSENT',
    'new_units': 'WABPPRIVSA',
    'altsales': 'ALTSALES',
    'totalsa': 'TOTALSA',
    'ltrucksa': 'LTRUCKSA',
    "tmaturity": 'T10Y2YM',
    "carcpi": 'CUSR0000SETA02',
    "newhouses": 'MSACSR',
    'pempltot': 'ADPMNUSNERNSA',
    'pemplmanuf': 'ADPMINDMANNERNSA',
    'pemplfin': 'ADPMINDFINNERNSA',
    'laborpart': 'CIVPART',
    'prodmanuf': 'AWHMAN',
    'overmanuf': 'AWOTMAN',
    'wagemanuf': 'CES3000000008',
    'fedsurplus': 'MTSDS133FMS',
    'industry': 'IPB50001N',
    'industrycg': 'IPCONGD',
    'industryut': 'IPG2211A2N',
    'caput': 'MCUMFN',
    'hcpiurban': 'CPIHOSSL',
    'stuffcpi': 'CUSR0000SAC',
    'retail': 'RSXFS',
    'sales':'TOTBUSSMSA',
    'manufsales': 'MNFCTRSMSA',
    'manufinv': 'MNFCTRIMSA',
    'cbpy30':'HQMCB30YRP',
    'fedfundseff':'FEDFUNDS',
    'treasurymat1': 'GS1',
    'treasurymat5': 'GS5',
    'treasurymat7': 'GS7',
    'treasurymat10': 'GS10'
    }
kw_list = ['new cars', 'used cars', 'cars for sale', 'car for sale near me', 'best new cars', 'how to buy a car', 'dealership near me', 'dealerships near me']

#===============================================================================

def rload(script, arglist):
  load = ["Rscript", "--vanilla", script, "--args"]
  load.extend(arglist)
  
  return(load)

# ============================ make logfile ====================================
logfile = "./logs/my_log_" + str(datetime.date.today()) + ".log"
# logging.basicConfig(format='[%(asctime)s] %(message)s', filename = logfile, encoding='utf-8', level = logging.INFO)
# 
# logging.basicConfig(format='[%(asctime)s] %(message)s', encoding='utf-8', level = logging.DEBUG)

log_info = logging.getLogger()
log_info("hello")
# log_info("Preparing data for {param_list[monthfile]} to estimate {param_list[targetvar]} for the next {ahead} months")
log_info("******************run params*****************")
log_info("partitition = {}".format(train_set))
log_info("y = {}".format(targetvar))
log_info("bloat = {}".format(bloat))
log_info("******************run params*****************")

log_info("Setting the standard for cor_max: {cor_max} and lead time: {ahead} months")

# logging.basicConfig(level=logging.DEBUG)
# logging.debug('This will get logged')

# def py_log(logfile, filelevel = logging.INFO):
#   
#     fmt = '%(levelname)s [%(asctime)s] %(message)s'
#     datefmt = '%Y-%m-%d %H:%M:%S'
#     
#     # create logger
#     logging.basicConfig(format = fmt, level = filelevel, datefmt = datefmt)
#     
#     logger = logging.getLogger(__name__)
#     
#     # create file handlers
#     fh = logging.FileHandler(logfile)
#     fh.setLevel(filelevel)
# 
#     ch = logging.StreamHandler()
# 
#     # create formatter
#     formatter = logging.Formatter(fmt = '%(levelname)s [%(asctime)s] %(message)s', datefmt = '%Y-%m-%d %H:%M:%S')
#     
#     # apply formatting
#     # fh.setFormatter(formatter)
#     # ch.setFormatter(formatter)
#     
#     logger.addHandler(fh)
#     logger.addhandler(ch)
#     # logger.setLevel(filelevel)
#     
#     return logger

tray = configurelog.get_logger(logfile)

# logging.FileHandler.close(fh)
tray.handlers.clear()
tray.info("HELLO")
log.warning("Hello")
# create file handler which logs even debug messages
# fh.setLevel(logging.DEBUG)

    # create logger
logger = logging.getLogger('simple_example')
logger.setLevel(logging.DEBUG)

fh = logging.FileHandler(logfile)
fh.setLevel(logging.DEBUG)

# create formatter
formatter = logging.Formatter('%(name)s %(levelname)s [%(asctime)s] %(message)s')

# add formatter to ch
fh.setFormatter(formatter)

# add ch to logger
logger.addHandler(fh)
logger.setLevel(logging.DEBUG)

logger.info("please work")
# print(a.stdout)
# "Rscript --vanilla -e 'rmarkdown::render(""/path/to/test.Rmd"", ""pdf_document"")'"
# "Rscript -e 'rmarkdown::render('test.Rmd')'"

# with subprocess.Popen(["Rscript", "--vanilla",  "Collage.R", "--args 12"], stdout=subprocess.PIPE) as proc:
#     table = proc.stdout.read()

def digest_data(arglist):
  a = subprocess.run(rload("transform.R", arglist), check = True, text = True) # get stdout??!?!?!
  b = subprocess.run(rload("fishing.R", arglist), check = True, text = True) # get stdout??!?!?!
  c = scrape.fetch_data(stocklist, fredpairs, kw_list)
  d = subprocess.run(rload("collage.R", arglist), check = True, text = True) # get stdout??!?!?!
  
scrape.fetch_data(stocklist, fredpairs, kw_list)


  




