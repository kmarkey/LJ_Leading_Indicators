# pybrain
import subprocess
import os
import logging
from thon.scrape import fetch_data
from thon.config import config_logger, config_rload
import datetime
#===============================================================================
logfile = "./logs/my_log_" + str(datetime.date.today()) + ".log"
log = config_logger(logfile)

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

log.critical(arglist)
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

# ============================ make logfile ====================================
# logging.basicConfig(format='[%(asctime)s] %(message)s', filename = logfile, encoding='utf-8', level = logging.INFO)
# 
# logging.basicConfig(format='[%(asctime)s] %(message)s', encoding='utf-8', level = logging.DEBUG)

log.info("hello")
# log_info("Preparing data for {param_list[monthfile]} to estimate {param_list[targetvar]} for the next {ahead} months")
log.info("******************run params*****************")
log.info("partitition = {}".format(train_set))
log.info("y = {}".format(targetvar))
log.info("bloat = {}".format(bloat))
log.info("******************run params*****************")

# print(a.stdout)
# "Rscript --vanilla -e 'rmarkdown::render(""/path/to/test.Rmd"", ""pdf_document"")'"
# "Rscript -e 'rmarkdown::render('test.Rmd')'"

# with subprocess.Popen(["Rscript", "--vanilla",  "Collage.R", "--args 12"], stdout=subprocess.PIPE) as proc:
#     table = proc.stdout.read()

def digest_data(arglist):
  a = subprocess.run(config_rload("transform.R", arglist), check = True, text = True) # get stdout??!?!?!
  b = subprocess.run(config_rload("fishing.R", arglist), check = True, text = True) # get stdout??!?!?!
  c = fetch_data(stocklist, fredpairs, kw_list)
  d = subprocess.run(config_rload("collage.R", arglist), check = True, text = True) # get stdout??!?!?!

digest_data(arglist)

  




