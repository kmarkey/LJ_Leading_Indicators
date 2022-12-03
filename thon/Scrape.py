# -*- coding: utf-8 -*-
#! env
"""
Created on Fri Jun  3 20:07:31 2022

@author: keato
"""

# free stock data with alpha vantage
import sys
import requests
import os
import pandas as pd
from alpha_vantage.timeseries import TimeSeries # AV
import pandas_datareader as pdr # access fred
from pytrends.request import TrendReq # google trends
from datetime import *
import time
import numpy as np
import webbrowser
import logging
from pytrends.exceptions import ResponseError
from thon.config import config_logger

########### Should use keys from LJLI gmail
#-------------------------

# log file
# run on the same date!
# logging.basicConfig(filename="./logs/my_log_" + str(datetime.date.today()) + ".log", encoding='utf-8', level=logging.DEBUG)

def get_keys(key_class, relpath = "./keys/keys.txt"):
    # not quite parsing correctly but still works with \n
    keys = {}
    
    try:
        with open(os.path.join(os.getcwd(), relpath)) as f:
            for line in f:
                k, v = line.split(",")
                keys[k] = v
           
    except FileNotFoundError:
        logging.exception("Key file not found")
      
    try:
          
            return keys[key_class]
          
    except KeyError:
      
        logging.exception("{} is not a valid key class".format(key_class))
    
    else:
      
        logging.exception("Error getting keys")

# https://github.com/RomelTorres/alpha_vantage

def get_search_bounds(relpath = "./keys/bounds.csv"):
    try:
      
        bounds = pd.read_csv(os.path.join(os.getcwd(), relpath)).to_dict(orient = 'list')
        
        lower = str(bounds.get("search_bottom")[0])
      
        upper = str(bounds.get("search_top")[0])
        
        logging.info("Lower bound set to: {l} and upper bound set to {u}".format(l = lower, u = upper))

    except FileNotFoundError:
        logging.exception("Bounds file not found")
      
    except KeyError:
        logging.exception("Bounds file formatted incorrectly")

    return lower, upper

#======================== simple data reuser for testing ======================?
def is_recyclable(data_class, lower_bound, upper_bound, n_cols):
  
  exist = pd.read_csv(os.path.join(os.getcwd(), "data/in/", data_class + ".csv"))
  
  logging.exception("{}".format(exist.shape))
  
  if lower_bound >= exist["date"].min() and upper_bound <= exist["date"].max() and n_cols <= exist.shape[1] - 1:
  
    return True
  
  else:
    
    return False #test

# def appending(filename, lower_bound, upper_bound, n_cols):
  # should always be true
  # perform munge sequence

#===============================================================================?
# stocklist = ["GM", "F", "TSLA", "AN", "MZDAY", "XOM", "TM", "LEA", "BWA", "VC", "GT", "NIO", "HMC", "RACE"]

def get_stock_csv(ticker, lower_bound, upper_bound, key = get_keys("alphavantage_key"), save = True):
    
    # trim first of month
    def trim_fom(df, lower_bound, upper_bound):
      # always date
        try:
            df['date'] = pd.to_datetime(df.date).dt.to_period('M').dt.to_timestamp()
            df = df.query('@lower_bound <= date <= @upper_bound')
        
            logging.debug("Stock successful")
            
        except KeyError:
            logging.exception("Column 'date' not found")
          
        return df
        
    def cleaner(df, tick):
        
        df = (df.sort_index(ascending = True)
                    .reset_index()
                    .rename({'4. close': '{}'.format(tick), 
                             '5. volume': '{}_v'.format(tick)}, 
                            axis = 'columns')
                    .loc[:, ['date', '{}'.format(tick), '{}_v'.format(tick)]]
                    .pipe(trim_fom, lower_bound=lower_bound, upper_bound=upper_bound))
        return df
    
    out = pd.DataFrame(columns = ['date'])
      
    ts = TimeSeries(key = key, output_format = "pandas")
      
    for tick in ticker:
        try:
            data, metadata = ts.get_monthly(symbol = tick)
            
            data = cleaner(data, tick)
          
        except ValueError:
            logging.exception("{} is not a valid API call and will be excluded".format(tick))
            continue
      
        out = out.merge(data, on = 'date', how = 'outer')
        
        if ticker.index(tick) % 5 == 4: # avoid AV timeout every 5
            logging.info("Sleeping for 60s to avoid AlphaVantage timeout")
            time.sleep(60)
            
    out = out.sort_values(by = 'date', ascending = True, ignore_index = True)
    
    if save == True:
        
        filename = os.path.join(os.getcwd(), "./data/in/stocks.csv")
        # save
        out.to_csv(filename, index = False)
          
        logging.info("stocks.csv", " (size ", len(out), ", ", len(out.columns), ") saved! \n", sep='')
    else:
        return out


#==============================================================================
""" check when data is updated"""

# fredpairs = {
#     'unemp': 'UNRATE',
#     'unempt5w': 'UEMPLT5',
#     'unemp5tp14w': 'UEMP5TO14',
#     'unemp15to26w': 'UEMP15T26',
#     'unemp15ov':'UEMP15T26',
#     'oilimport': 'IR10000',
#     'ngspot': 'MHHNGSP',
#     'hcpi': 'CUURA400SAH',
#     'food': 'CUURA423SAF11',
#     'sahmrule': 'SAHMREALTIME',
#     'discount': 'TB3MS',
#     'localrent': 'CUURA423SEHA',
#     'durable': 'DGORDER',
#     '10yinf': 'T10YIEM',
#     'kwhcost': 'APUS49D72610',
#     'sentiment': 'UMCSENT',
#     'new_units': 'WABPPRIVSA',
#     'altsales': 'ALTSALES',
#     'totalsa': 'TOTALSA',
#     'ltrucksa': 'LTRUCKSA',
#     "tmaturity": 'T10Y2YM',
#     "carcpi": 'CUSR0000SETA02',
#     "newhouses": 'MSACSR',
#     'pempltot': 'ADPMNUSNERNSA',
#     'pemplmanuf': 'ADPMINDMANNERNSA',
#     'pemplfin': 'ADPMINDFINNERNSA',
#     'laborpart': 'CIVPART',
#     'prodmanuf': 'AWHMAN',
#     'overmanuf': 'AWOTMAN',
#     'wagemanuf': 'CES3000000008',
#     'fedsurplus': 'MTSDS133FMS',
#     'industry': 'IPB50001N',
#     'industrycg': 'IPCONGD',
#     'industryut': 'IPG2211A2N',
#     'caput': 'MCUMFN',
#     'hcpiurban': 'CPIHOSSL',
#     'stuffcpi': 'CUSR0000SAC',
#     'retail': 'RSXFS',
#     'sales':'TOTBUSSMSA',
#     'manufsales': 'MNFCTRSMSA',
#     'manufinv': 'MNFCTRIMSA',
#     'cbpy30':'HQMCB30YRP',
#     'fedfundseff':'FEDFUNDS',
#     'treasurymat1': 'GS1',
#     'treasurymat5': 'GS5',
#     'treasurymat7': 'GS7',
#     'treasurymat10': 'GS10'
#     }
      
def get_fred_csv(names_dict, lower_bound, upper_bound, key = get_keys("fred_key"), save = True):
  
    # reverse dict
    names = {v: k for k, v in names_dict.items()}
    
    values = names_dict.values()
    
    try:
        df = pdr.DataReader(values, 'fred', lower_bound, upper_bound, api_key = key)
      
        out = (df.reset_index()
                .rename({'DATE': 'date'}, axis = 'columns')
                .rename(columns = names)
                .sort_values(by = 'date', ascending = True, ignore_index = True))
        
        logging.info("FRED data recieved")
      
    except:
        logging.exception("A FRED call is invalid")

        out = pd.DataFrame({'date': []})
      
    # rename
    if save == True and out.empty == False:
        filename = os.path.join(os.getcwd(), "./data/in/fred.csv")
        
      # save
        out.to_csv(filename, index = False)
        
        logging.info("fred.csv (size ", len(out), ", ", len(out.columns), ") saved! \n", sep = '')
    elif out.empty == True:
        logging.exception("FRED data empty")
      
    else:
        return out


#==============================================================================
# get google trends data
# https://lazarinastoy.com/the-ultimate-guide-to-pytrends-google-trends-api-with-python/#:~:text=Google%20Trends%20is%20a%20public,trending%20results%20from%20google%20trends.
# requests_args=time.sleep(1)

# kw_list = ['new cars', 'used cars', 'cars for sale', 'car for sale near me', 'best new cars', 'how to buy a car', 'dealership near me', 'dealerships near me']
def get_trend_csv(word_list, lower_bound, upper_bound, gusr = get_keys("google_usr"), gpass = get_keys("google_pass"), save = True):
  
    dataset = []
    
    # setup trend obj
    tob = TrendReq(hl='en-US', timeout=(25), tz=480, retries = 2, backoff_factor = 0.1,
                    requests_args={'auth':(gusr, gpass)})
    
    n_tries = 0
    
    if tob.google_rl != None:
        logging.info("{}".format(tob.google_rl))
    
  # try connection thrice
    while n_tries < 3:
        try:
            for x in range(len(word_list)):
              
                keyword = [word_list[x]]
                 
                tob.build_payload(kw_list = keyword, cat = 0,
                timeframe = lower_bound + " " + upper_bound,
                geo = 'US-WA-819')
                 
                data = tob.interest_over_time()
                 
                if not data.empty:
                    data = data.drop(labels = ['isPartial'], axis = 'columns')
                      
                    dataset.append(data)
                    
                    logging.info("{} data recieved".format(word_list[x]))

                if data.empty:
                    logging.info("{} not found. Continuing.".format(word_list[x]))
            break          
        except (ResponseError, requests.exceptions.Timeout):
            logging.info("Google Trends request failed, opening https://trends.google.com/trends/?geo=US for cars")
        
            # open url connection
            webbrowser.open("https://trends.google.com/trends/explore?date=2015-01-01%202022-09-01&geo=US&q=cars")
            
            # seperate requests a bit
            time.sleep(5)
        
        n_tries += 1
    try:
        result = pd.concat(dataset, axis = 1).add_prefix("g_").reset_index()
    
        result.columns = result.columns.str.replace(" ", "_")
        
    except ValueError:
      
        logging.exception("Dataframe empty: {}".format(tob.google_rl))
        
        result = pd.DataFrame({'date': []})
        
    if save == True and result.empty == False:
        filename = os.path.join(os.getcwd(), "./data/in/trends.csv")
        
        # save
        result.to_csv(filename, index = False)
        
        logging.info("trends.csv, size", len(result), ":", len(result.columns), ", saved \n")
    else:
        logging.info("returning result")
        return result
      

def fetch_data(stocklist, freddict, trendlist):
  
  bottom, top = get_search_bounds()

  get_stock_csv(stocklist, bottom, top, key = get_keys("alphavantage_key"))
  
  get_fred_csv(freddict, bottom, top, key = get_keys("fred_key"))
  
  get_trend_csv(trendlist, bottom, top)

