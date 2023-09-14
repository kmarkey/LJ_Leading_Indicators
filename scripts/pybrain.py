# pybrain
import subprocess
import os
import logging
from thon.hooks import collect_all
from thon.config import config_logger, close_logger, config_rload
from datetime import date, time, datetime

#===============================================================================
log = config_logger()

os.chdir("C:/Users/keato/Documents/LocalRStudio/LJ_Leading_Indicators/")

fetch_args = {"cor_max": 0.20, # set feature correlation cutoff
              "ahead": 3, # set lead time in months (3)
              "train_set": "all", # data subset being used
              "targetvar": "n", # variable of interest
              "bloat": False # favor wide over long feature data
}

arglist = ["cor_max {}".format(fetch_args["cor_max"]), 
           "ahead {}".format(fetch_args["ahead"]), 
           "train_set {}".format(fetch_args["train_set"]), 
           "targetvar {}".format(fetch_args["targetvar"]), 
           "bloat {}".format(fetch_args["bloat"])]

arglist
#===============================================================================
stocklist = ["GM", "F", "TSLA", "AN", "MZDAY", "XOM", "TM", "LEA", "BWA", "VC", "GT", "NIO", "HMC", "RACE"]

fredpairs = {
    'unemp': 'UNRATE',
    'unempt5w': 'UEMPLT5',
    'unemp5tp14w': 'UEMP5TO14',
    'unemp15to26w': 'UEMP15T26',
    'unemp27ov':'UEMP27OV',
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

glist = ['new cars', 'used cars', 'cars for sale', 'car for sale near me', 'best new cars', 'how to buy a car', 'dealership near me', 'dealerships near me']
#===============================================================================

# log_info("Preparing data for {param_list[monthfile]} to estimate {param_list[targetvar]} for the next {ahead} months")
log.info("******************run params*****************")
log.info(str(fetch_args))
log.info("******************run params*****************")

# print(a.stdout)
# "Rscript --vanilla -e 'rmarkdown::render(""/path/to/test.Rmd"", ""pdf_document"")'"
# "Rscript -e 'rmarkdown::render('test.Rmd')'"

# with subprocess.Popen(["Rscript", "--vanilla",  "Collage.R", "--args 12"], stdout=subprocess.PIPE) as proc:
#     table = proc.stdout.read()

def fetch_data(arglist):
  a = subprocess.run(config_rload("transform.R", arglist), check = True, text = True) # get stdout??!?!?!
  b = subprocess.run(config_rload("fishing.R", arglist), check = True, text = True) # get stdout??!?!?!
  c = collect_all(stocklist, fredpairs, glist)
  d = subprocess.run(config_rload("collage.R", arglist), check = True, text = True) # get stdout??!?!?!

# def train_models():

# def eval_models()
#   
# def indicate():
collect_all(stocklist, fredpairs, glist)

