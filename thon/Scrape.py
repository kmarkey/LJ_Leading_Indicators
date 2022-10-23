# -*- coding: utf-8 -*-
#! env
"""
Created on Fri Jun  3 20:07:31 2022

@author: keato
"""

# free stock data with alpha vantage
import requests
import os
import pandas as pd
from alpha_vantage.timeseries import TimeSeries # AV
import pandas_datareader as pdr # access fred
from pytrends.request import TrendReq # google trends
from datetime import datetime
import time

#-------------------------
os.chdir('C:\\Users\\keato\\Documents\\LocalRStudio\\LJ_Leading_Indicators')
#-------------------------

def get_keys(path = "keys/keys.txt"):
    keys = {}
    with open(os.path.join(os.getcwd(), path)) as f:
        for line in f:
           k, v = line.split(",")
           keys[k] = v
    alphavantage_key = keys["alphavantage_key"]
    fred_key = keys["fred_key"]
    return alphavantage_key, fred_key
# Your key here
# https://github.com/RomelTorres/alpha_vantage
avkey, fredkey = get_keys()

def get_search_bounds(path): # reference csv file
    bounds = pd.read_csv(os.path.join(os.getcwd(), "keys/bounds.csv")).to_dict(orient = 'list')
    lower = str(bounds.get("search_bottom")[0])
    upper = str(bounds.get("search_top")[0])
    print("Using lower:", lower, "and upper:", upper)
    return lower, upper

search_bottom, search_top = get_search_bounds("keys/bounds.csv")

#==============================================================================
stocklist = ["GM", "F", "TSLA", "AN", "MZDAY", "XOM"]

# make 1 df
def get_ticker_csv(ticker, lower_bound = "2015-01-01", upper_bound = "2020-02-29", key = avkey, save = True):
    out = pd.DataFrame(columns=['date'])
    ts = TimeSeries(key = key, output_format = "pandas")
    
    for tick in ticker:
        data, metadata = ts.get_monthly(symbol = tick)
        data = data.sort_index().loc[lower_bound:upper_bound]
        data = data.reset_index()
        data = data.rename({'4. close': '{0}'.format(tick), 
                            '5. volume': '{0}_v'.format(tick)}, axis='columns')
        data = data[['date', '{0}'.format(tick), '{0}_v'.format(tick)]]
        data['date'] = pd.to_datetime(data.date).dt.to_period('M').dt.to_timestamp()
        out = out.merge(data, on = 'date', how = 'right')
        if ticker.index(tick) % 5 == 0: # avoid AV timeout
            time.sleep(60)
    if save == True:
        savename = 'stocks.csv'
        filename = os.path.join(os.getcwd(), "data/in/", savename)
        # save
        out.to_csv(filename, index = False)
        return print(savename, " (size ", len(out), ", ", len(out.columns), ") saved! \n", sep='')
    else:
        return out

# GM
get_ticker_csv(stocklist, search_bottom, search_top, save = True)

# c confidence, c price index, durable goods /orders?, unemployment

#==============================================================================
fredpairs = {
    'unemployment': 'UNRATE',
    'localrent': 'CUURA423SEHA',
    'durable': 'DGORDER',
    '10yinf': 'T10YIEM',
    'kwhcost': 'APUS49D72610',
    'sentiment': 'UMCSENT',
    'new_units': 'WABPPRIVSA',
    'altsales': 'ALTSALES',
    'totalsa': 'TOTALSA',
    'ltrucksa': 'LTRUCKSA',
    "miles": "TRFVOLUSM227NFWA",
    "tmaturity": "T10Y2YM",
    "carcpi": "CUSR0000SETA02",
    "newhouses": "MSACSR"
    }

fredpairs.values()

def get_fred_data(names_dict, lower_bound = "2015-01-01", upper_bound = "2020-02-29", save = True):
    # reverse dictionary
    names = {v: k for k, v in names_dict.items()}
    values = names_dict.values()
    
    df = pdr.DataReader(values, 'fred', lower_bound, upper_bound)
    df = df.reset_index()
    df =  df.rename({'DATE': 'date'}, axis = 'columns')
    out = df.rename(columns = names)

    # rename
    if save == True:
        filename = os.path.join(os.getcwd(), "data/in/fred.csv")
      # save
        out.to_csv(filename, index = False)
        return print("fred.csv (size ", len(out), ", ", len(out.columns), ") saved! \n", sep = '')
    else:
        return out

# get data
get_fred_data(fredpairs, lower_bound=search_bottom, upper_bound=search_top, save = True)

#==============================================================================
# get google trends data
# https://lazarinastoy.com/the-ultimate-guide-to-pytrends-google-trends-api-with-python/#:~:text=Google%20Trends%20is%20a%20public,trending%20results%20from%20google%20trends.
# requests_args=time.sleep(1)

kw_list=['new cars', 'used cars', 'car', 'car for sale near me', 'best new cars', 'tips for buying a car']

def get_trends(word_list, lower_bound, upper_bound, save = True):
    dataset = []
    pytrend = TrendReq(retries=5)
    for x in range(0,len(word_list)):
         keywords = [word_list[x]]
         pytrend.build_payload(
         kw_list=keywords,
         cat=0,
         timeframe=lower_bound + " " + upper_bound,
         geo='US')
         data = pytrend.interest_over_time()
         if not data.empty:
              data = data.drop(labels=['isPartial'],axis='columns')
              dataset.append(data)
    result = pd.concat(dataset, axis=1).add_prefix("g_").reset_index()
    result.columns = result.columns.str.replace(" ", "_")
    
    if save == True:
        filename = os.path.join(os.getcwd(), "data/in/trends.csv")
        # save
        result.to_csv(filename, index = False)
        return print("trends.csv, size", len(result), ":", len(result.columns), ", saved \n")
    else:
        return result
    # result.to_csv('search_trends.csv')

result = get_trends(kw_list, lower_bound = search_bottom, upper_bound= search_top, save = True) # weird behavior
# url = str('https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol=' + tick + '&apikey=' + key + '&datatype=' + datatype)