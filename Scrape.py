# -*- coding: utf-8 -*-
"""
Created on Fri Jun  3 20:07:31 2022

@author: keato
"""

# free stock data with alpha vantage
import requests
import os
import pandas as pd
from alpha_vantage.timeseries import TimeSeries
import pandas_datareader as pdr # access fred
from datetime import datetime
import time

os.chdir('C:\\Users\\keato\\Documents\\LocalRStudio\\LJ_Leading_Indicators')

os.getcwd()

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
# key = 'yourkeyhere'
# https://github.com/RomelTorres/alpha_vantage
avkey, fredkey = get_keys()

def get_search_bounds(path = "."): # willeventually reference csv file
    lower = "2015-01-01"
    upper = "2020-02-29"
    return lower, upper

search_bottom, search_top = get_search_bounds()


def get_ticker_csv(ticker, lower_bound = "2015-01-01", upper_bound = "2020-02-29", key = avkey, save = True):
    ts = TimeSeries(key = key, output_format = "pandas")
    data, metadata = ts.get_monthly(symbol = ticker)
    data = data.sort_index().loc[lower_bound:upper_bound]
    data = data.reset_index()
    data = data.rename({'4. close': '{0}'.format(ticker), 
                        '5. volume': '{0}_v'.format(ticker)}, axis='columns')
    data = data[['date', '{0}'.format(ticker), '{0}_v'.format(ticker)]]
    data['date'] = pd.to_datetime(data.date).dt.to_period('M').dt.to_timestamp()
#==============================================================================
    if save == True:
        savename = metadata['2. Symbol'] + '.csv'
        filename = os.path.join(os.getcwd(), "data/in/stocks/", savename)
        # save
        data.to_csv(filename, index = False)
        
    return print(savename,", size", len(data), ":", len(data.columns), ", saved \n")

# GM
get_ticker_csv("GM", search_bottom, search_top, save = True)

# Ford
get_ticker_csv("F", search_bottom, search_top, save = True)

# Tesla
get_ticker_csv("TSLA", search_bottom, search_top, save = True)


# get_ticker_csv("CVNA", avkey, search_bottom, search_top, save = True) stock is too new

# Autonation
get_ticker_csv("AN", search_bottom, search_top, save = True)

# Hyundai for kia, no data before 2016?????
# get_ticker_csv("HYMTF", "2014-01-01", search_top, save = True)

time.sleep(60) # call rate is 5/min

# Mazda
get_ticker_csv("MZDAY", search_bottom, search_top, save = True)


# get_ticker_csv("SP500", avkey, search_bottom, search_top, save = True)


# c confidence, c price index, durable goods /orders?, unemployment

#==============================================================================
series = {
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

# reverse dictionary
names = {v: k for k, v in series.items()}

def get_fred_data(param_list, lower_bound = "2015-01-01", upper_bound = "2020-02-29"):
  df = pdr.DataReader(param_list, 'fred', lower_bound, upper_bound)
  df = df.reset_index()
  df =  df.rename({'DATE': 'date'}, axis = 'columns')
  return df

# get data
df = get_fred_data(list(series.values()), 
                   lower_bound=search_bottom, 
                   upper_bound=search_top)

df = df.rename(columns = names)

def save_fred_data(data):
    filename = os.path.join(os.getcwd(), "data/in/fred.csv")
    # save
    data.to_csv(filename, index = False)
    return print("fred.csv, size", len(data), ":", len(data.columns), ", saved \n")
    
save_fred_data(df)
    

#==============================================================================
# get google trends data
# https://lazarinastoy.com/the-ultimate-guide-to-pytrends-google-trends-api-with-python/#:~:text=Google%20Trends%20is%20a%20public,trending%20results%20from%20google%20trends.

from pytrends.request import TrendReq
pytrend = TrendReq(requests_args=time.sleep(10), retries=5)
# requests_args=time.sleep(1)
kw_list=['GM', 'car', 'car sales near me', 'best new cars']


def get_trends(word_list, lower_bound, upper_bound):
    dataset = []
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
    return result
    # result.to_csv('search_trends.csv')

result = get_trends(kw_list, lower_bound = "2015-01-01", upper_bound= "2020-03-05") # weird behavior

def save_google_data(data):
    filename = os.path.join(os.getcwd(), "data/in/trends.csv")
    # save
    data.to_csv(filename, index = False)
    return print("trends.csv, size", len(data), ":", len(data.columns), ", saved \n")

save_google_data(result)

# url = str('https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol=' + tick + '&apikey=' + key + '&datatype=' + datatype)

# # with requests.get(url, stream = True) as r:
# #     reader = iterdecode(csv.reader(r.iter_lines(), ''), 
# #                         delimiter=',', 
# #                         quotechar='"'
# #                         )
# #    for row in reader:
# #        print(row)

# # with requests.get(url) as csvfile:
# #      spamreader = csv.reader(csvfile, delimiter=',', quotechar='"')Alpha
# #      for row in spamreader:
# #          print(', '.join(row))
         
# r = requests.get(url)

# response_dict = r.json()
# _, header = response.json()

# # remember it returns a tuple, the first being a _csv.reader object
# aapl_csvreader, meta = ts.get_daily(symbol='GM')


# def request_stock_price_hist(symbol, token, sample = False):
#     if sample == False:
#         q_string = 'https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol={}&outputsize=full&apikey={}'
#     else:
#         q_string = 'https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol={}&apikey={}'

#     print("Retrieving stock price data from Alpha Vantage (This may take a while)...")
#     r = requests.get(q_string.format(symbol, token))
#     print("Data has been successfully downloaded...")
#     date = []
#     colnames = list(range(0, 7))
#     df = pd.DataFrame(columns = colnames)
#     print("Sorting the retrieved data into a dataframe...")
#     for i in tqdm(r.json()['Monthly Time Series'].keys()):
#         date.append(i)
#         row = pd.DataFrame.from_dict(r.json()['Monthly Time Series'][i], orient='index').reset_index().T[1:]
#         df = pd.concat([df, row], ignore_index=True)
#     df.columns = ["open", "high", "low", "close", "adjusted close", "volume", "dividend amount", "split cf"]
#     df['date'] = date
#     return df

# df = request_stock_price_hist("GM", key)


# os.chdir('C:/Users/keato/Documents/LocalRStudio/LJ_Leading_Indicators')

# # replace the "demo" apikey below with your own key from https://www.alphavantage.co/support/#api-key



# tdict = r.json()['Monthly Time Series']
# tdict1 = tdict[1]
# jdict = pd.json_normalize(tdict, ['4. close'])
# len(tdict)
# ####################################################
# with open("data/json/GM.json", "w") as outfile:
#     outfile.write(jdict)

# #with open("sample.json", "w") as outfile:
# #    json.dump(tdict, outfile)

# with open('data/json/GM.json','r') as f:
#     data = json.loads(f.read())

# #############################################################
# def get_ticker(url, dict_type = 'list'):
#     data = pd.read_json(url, 'records')
#     trim = data.iloc[4:]
#     r = requests.get(url)
#     tdict = r.json()
#     #trim = trim.drop("Meta Data", 1)
#     #df = data.to_dict(dict_type)
#     norm = pd.json_normalize(tdict)
#     return norm
# tdict
# b = get_ticker(url = url, dict_type = 'list')
# d = pd.read_json(url, orient = "records")
# trim = d.iloc[4:].drop("Meta Data", axis = 1)

# trim = 
# tdict = trim.to_dict(orient = "index")
# norm = pd.json_normalize(tdict)

# data = pd.read_json(url, orient = 'records')
# f = get_ticker(url)

# d = pd.json_normalize(tdict, record_path=['Monthly Time Series'])
