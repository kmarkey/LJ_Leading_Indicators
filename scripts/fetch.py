import subprocess
import os
import logging
import pandas as pd
from scripts.hooks import collect_data, collect_info
from scripts.config import config_logger, close_logger
import datetime

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

# get bounds
data = pd.read_csv("./data/sour/KDAc.csv")
search_lower = str(datetime.datetime.strptime(data[['date']].min().iloc[0], "%Y-%m-%d") + pd.offsets.MonthBegin(-1) + pd.offsets.YearBegin(-1))[:10] 

# what really matters::
def end_of_month(dt):
    todays_month = dt.month
    tomorrows_month = (dt + datetime.timedelta(days=1)).month
    return tomorrows_month != todays_month
  
max_kda_date = datetime.datetime.strptime(data[['date']].max().iloc[0], "%Y-%m-%d")

if end_of_month(max_kda_date):
  search_upper =  str(max_kda_date)[:10]
else:
  search_upper = str(datetime.datetime.strptime(data[['date']].max().iloc[0], "%Y-%m-%d") + pd.offsets.MonthEnd(-1))[:10]


collect_data(stocklist, fredpairs, glist, search_lower=search_lower, search_upper = search_upper)

collect_info(stocklist, fredpairs, glist, search_lower=search_lower, search_upper = search_upper)

