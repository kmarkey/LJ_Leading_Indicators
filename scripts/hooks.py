# manage stock data:
import os
import requests
import json
import pandas as pd
import re
from scripts.py_utilities import config_logger, close_logger, get_newest_dir_py, get_newest_file_py
import datetime
import time
from alpha_vantage.timeseries import TimeSeries # AV
import pandas_datareader as pdr # access fred
import webbrowser
from pytrends.exceptions import ResponseError
from pytrends.request import TrendReq # google trends
from bs4 import BeautifulSoup

class manager:
    
    def __init__(self, name_class, keyname = None, search_lower = None, search_upper = None, keypath = "./keys/keys.txt", runpath = "./logs/"):
        
        self.log = config_logger()
        
        # should read key from environment, else file
        if keyname == None:
            self.key = self.__key_from_file__(keyname = keyname, keypath = keypath)
        else:
            self.log.info("Key read from env")
            self.key = os.getenv(keyname)
            
        # should never read bounds from file
        self.search_lower = search_lower
        
        self.search_upper = search_upper
        
        self.name_class = name_class
        
        # outfile path
        self.path = os.path.join(os.getcwd(), "./data/in/{}.csv".format(self.name_class))
        
        # read existing file from same path
        if os.path.exists(self.path):
          
            self.exist = pd.read_csv(self.path)
            
        else:
          
            # will throw ERROR if doesn;t exist
            self.exist = False
            
        close_logger(self.log)
            
        # secrets??
        
    def __key_from_file__(self, keyname, keypath):
      
        # not quite parsing correctly but still works with \n
        keys = {}
        
        try:
            with open(os.path.join(os.getcwd(), keypath)) as f:
                for line in f:
                    k, v = line.split(",")
                    keys[k] = v
              
            return keys[keyname]
              
            self.log.debug("Key file read")
            
        except FileNotFoundError:
          
            self.log.exception("Key file not found")
              
        except KeyError:
          
            self.log.exception("{} is not a valid key class".format(keyname))
        
        except:
          
            self.log.error("Error getting keys")
            
            return None
            
        close_logger(self.log)
    
    # test to see if saved file can be reused
    # only if same exatc dimensions
    @property
    def recyclable(self):
        
        try:
            if (datetime.datetime.strptime(self.search_lower, "%Y-%m-%d").month >= datetime.datetime.strptime(str(self.exist["date"].min()), "%Y-%m-%d").month and
                datetime.datetime.strptime(self.search_lower, "%Y-%m-%d").year >= datetime.datetime.strptime(str(self.exist["date"].min()), "%Y-%m-%d").year and
                datetime.datetime.strptime(self.search_upper, "%Y-%m-%d").month <= datetime.datetime.strptime(str(self.exist["date"].max()), "%Y-%m-%d").month and
                datetime.datetime.strptime(self.search_upper, "%Y-%m-%d").year <= datetime.datetime.strptime(str(self.exist["date"].max()), "%Y-%m-%d").year and
                len(self.food) == self.exist.shape[1] - 1): # exact same length
                 
                return True
                
            else:
                
                return False
        except:
          
            self.log.info("Existing {} file not read".format(self.name_class))
            
            return False
            
    # save functions
    def save_data(self, out):
        
        out.to_csv(self.path, index = False)
        
        self.log.info("".join(["{}.csv size: ".format(self.name_class), out.shape, ", saved!"]))
        
        close_logger(self.log)
        
        return
        
    def save_info(self, info):
        
        with open("./data/out/{}_info.json".format(self.name_class), "w") as outfile:
            
            json.dump(info, outfile)
            
        self.log.info("".join(["{}_info.json saved!".format(self.name_class)]))
        
        close_logger(self.log)
        
        return

class stocks(manager):  
    
    #  set defaults for stocks
    def __init__(self, search_lower = None, search_upper = None, keyname = "alphavantage_key", name_class = "stocks"):
        
        super().__init__(search_lower = search_lower, search_upper = search_upper, keyname = keyname, name_class = name_class)
        
    def get_csv(self, stocklist, save = True):
      
        self.food = stocklist # gets fed into get_csv
        
        if self.recyclable == True and save == False:
            
            self.log.info("{name}.csv, size:{dim}, will be reused!".format(name = self.name_class, dim = self.exist.shape))
            
            # new self.data
            self.data = self.exist
            
            return self.data
            
        elif self.recyclable == True and save == True:
            
            self.log.info("{name}.csv, size: {dim}, can be reused! Leaving {name}.csv untouched".format(name = self.name_class, dim = self.exist.shape))
            
            self.data = self.exist
            
        else:
            
        # trim first of month from alphavantage request
            def fetch_av(tick):
                
                self.log.info("Fethcing {} stock data".format(tick))
                url = 'https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY_ADJUSTED&symbol={0}&apikey={1}&datatype=json'.format(tick, self.key)
    
                r = requests.get(url)
                
                data = r.json()
                
                try:
                    data = data['Monthly Adjusted Time Series']
                  
                except (KeyError):
                  
                    ############# log msg
                    self.log.error("AlphaVantage daily limit reached, {} not fetched".format(tick))
                    
                    return pd.DataFrame(columns = ['date'])
                  
                # get whole df
                whole = pd.DataFrame(data.items())
                
                if whole.empty:
                  
                    self.log.warning("{} dataframe was empty".format(tick))
                    
                    return pd.DataFrame(columns = ['date'])
                  
                # select values from column 1
                v = pd.json_normalize(whole.loc[:,1])
                
                # bring together
                p = (pd.concat([whole.loc[:,0]
                        .reset_index(drop=True), v], axis=1)
                        .rename(columns = {0: 'date',
                                      '4. close': '{}'.format(tick),
                                      '6. volume': '{}_v'.format(tick)}, errors="raise")
                        .loc[:, ['date', '{}'.format(tick), '{}_v'.format(tick)]])
                
                # report shape for each tick
                self.log.info(tick + ": " + str(p.shape[0]) + " " + str(p.shape[1]))
                
                # make date first of month
                p['date'] = p['date'].map(lambda x: x[:-2] + "01")
                
                return(p)
              
            # empty df
            out = pd.DataFrame(columns = ['date'])
            
            i = 0
            
            for tick in stocklist:
                
                data = fetch_av(tick)
                
                if data == None:
                    pass
                
                out = out.merge(data, on = 'date', how = 'outer')
                
                i += 1
                
                if i % 5 == 4:
                    # pause to avoid rate limit
                    
                    self.log.info("Pause for AlphaVantage RL")
                    
                    time.sleep(60)
                    
            out = out.sort_values(by = 'date', ascending = True, ignore_index = True)
            
            print(out.shape)
            
            out = out.loc[(out[['date']] >= self.search_lower) & (out[['date']] <= self.search_upper)].reset_index(drop = True)
            
            if save == True:
                # save
                self.save_data(out)
                
            else:
              
                return out
                
    def get_info(self, stocklist, save = True):
        
        tdict = {}
        
        for s in stocklist:
          
            url = "https://finance.yahoo.com/quote/{}/profile".format(s)
                    
            response = requests.get(url, timeout = 10)
            
            if response.status_code == 404:
                
                headers = {"User-Agent": "Chrome/71.0.3578.98"}
                
                response = requests.get(url, headers = headers, timeout = 10)
                
            soup = BeautifulSoup(response.text, 'html.parser')
                
            try:
                
                name = soup.find('h1', {"class": "D(ib) Fz(18px)"}).text.strip()
            
            except:
                
                name = ""
                
                self.log.info("Could not find name for {}".format(s))
                
            code = s
            
            updated = str(datetime.datetime.now().strftime("%b %#d, %Y %#I:%M %p"))
            
            try:
                
                category = "".join([soup.find(string = "Sector(s)").findNext('span').text, 
                                   ", ",
                                   soup.find(string = "Industry").findNext('span').text])
                
            except:
                
                category = ""
                
                self.log.info("Could not find category for {}".format(s))
                
            citation = "".join([name, ", [", code, "], ", "retrieved from Alpha Vantage Inc.", 
                                ", ", str(datetime.datetime.now().strftime("%b %#d, %Y")), "."])
            
            tdict[s] = {"name": name, "code": code, "updated": updated, "category": category, 
                        "citation": citation, "link": url}
            
        self.info = tdict
        
        if save == True:
            
            self.save_info(tdict)
            
            return
            
        else:
            
            return tdict
          
    def collect(self, stocklist, save = True):
        
        self.get_csv(stocklicst = stocklist, save = save)
        
        self.get_info(stocklist = stocklist, save = save)
        
        return

class fred(manager):
    
    def __init__(self, search_lower = None, search_upper = None, keyname = "fred_key", name_class = "fred"):
        
        super().__init__(search_lower = search_lower, search_upper = search_upper, keyname = keyname, name_class = name_class)
        
    def get_csv(self, fredpairs, save = True):
        
        self.rev = {v: k for k, v in fredpairs.items()}
        
        self.food = list(fredpairs.values())
        
        self.names = list(fredpairs.keys())
        
        if self.recyclable == True and save == False:
            
            self.log.info("{name}.csv, size:{dim}, will be reused!".format(name = self.name_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return self.data
        
        if self.recyclable == True and save == True:
            
            self.log.info("{name}.csv, size: {dim}, can be reused! Leaving {name}.csv untouched".format(name = self.name_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return
            
        else:
          
            try:
                
                df = pdr.DataReader(self.food, self.name_class, self.search_lower, self.search_upper, api_key = self.key)
                
                out = (df.reset_index()
                        .rename({'DATE': 'date'}, axis = 'columns')
                        .rename(columns = self.rev)
                        .sort_values(by = 'date', ascending = True, ignore_index = True))
                
                self.log.info("Fred data recieved")
          
            except:
              
                self.log.exception("A Fred call is invalid")
                
                out = pd.DataFrame({'date': []})
                
            self.data = out
            
            if save == True:
                # save
                self.save_data(out)
                
            else:
              
                return out
          
    def get_info(self, fredpairs, save = True):
        
        tdict = {}
        
        self.log.info("Getting Fred info")
        
        for k, v in fredpairs.items():
            
            url = "https://fred.stlouisfed.org/series/{}".format(v)
        
            response = requests.get(url, timeout = 5)
        
            try:
                soup = BeautifulSoup(response.text, 'html.parser')
        
                name = soup.find('span', {'id': 'series-title-text-container'}).text.strip()
                
                updated = soup.find('span', {'class': 'updated-text'})['title']
                
                try:
                    
                    category = soup.find('a', {'class': 'note-release series-release fg-ext-link-gtm fg-release-link-gtm'}).text.strip()
                
                except:
                    
                    try:
                        
                        category = soup.find('p', {'class': 'col-xs-12 col-md-6 pull-left'}).text.strip().replace("  ", "").split("\n")[1]
                        
                    except:
                        
                        try:

                            category = soup.find('p', {'class': 'col-12 col-md-6 float-start mb-2'}).text.strip().replace("  ", "").split("\n")[1]
                            
                        except:
                            
                            category = None
                            
                finally:
                            
                    citation = soup.find('p', {'class': 'citation'}).text.strip().replace("  ", "").replace("\n", " ")
                    
                    tdict[k] = {"name": name, "code": v, "updated": updated, "category": category, 
                                "citation": citation, "link": url}
            except:
                
                self.log.info("Fred code {} not found".format(v))
                
        self.info = tdict
        
        if save == True:
            
            self.save_info(tdict)
            
        else:
            
            return tdict
            
    def collect(self, fredpairs, save = True):
        
        self.get_csv(fredpairs = fredpairs, save = save)
        
        self.get_info(fredpairs = fredpairs, save = save)

class trends(manager):
    
    def __init__(self, search_lower = None, search_upper = None, keyname = "google_usr", name_class = "trends"):
        
        super().__init__(search_lower = search_lower, search_upper = search_upper, keyname = keyname, name_class = name_class)
        
    def get_csv(self, glist, save = True):
    
        self.food = glist
        
        self.data = []
        
        # setup trend obj
        
        tob = TrendReq(hl='en-US', timeout=(10), tz=480, retries = 2, backoff_factor = 0.1)
        
        n_tries = 0
        
        if tob.google_rl != None:
            
            self.log.info("Google rate Message: {}".format(tob.google_rl))
            
        if self.recyclable == True and save == False:
            
            self.log.info("{name}.csv, size:{dim}, will be reused!".format(name = self.name_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return self.data
        
        if self.recyclable == True and save == True:
            
            self.log.info("{name}.csv, size: {dim}, can be reused! Leaving {name}.csv untouched".format(name = self.name_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return
          
        while n_tries < 3:
            
            try:
                
                for x in range(len(glist)):
                  
                    keyword = glist[x]
                    
                    tob.build_payload(kw_list = [keyword], cat = 0,
                                      timeframe = " ".join([self.search_lower, self.search_upper]))
                     
                    df = tob.interest_over_time()
                     
                    if not df.empty:
                        
                        df = df.drop(labels = ['isPartial'], axis = 'columns')
                          
                        self.data.append(df)
                        
                        self.log.debug("{} data recieved".format(glist[x]))
                        
                    else:
                        
                        self.log.info("{} not found. Continuing.".format(glist[x]))
                        
                break       
                
            # if above errors, run this
            except (ResponseError, requests.exceptions.Timeout):
                
                self.log.info("Google Trends request failed, opening https://trends.google.com/trends/?geo=US for cars")
                
                # open url connection
                webbrowser.open("https://trends.google.com/trends/explore?date=2015-01-01%202022-09-01&geo=US&q=cars")
                
                # seperate requests a bit
                time.sleep(5)
            
            n_tries += 1
            
        try:
            
            out = pd.concat(self.data, axis = 1).add_prefix("g_").reset_index()
        
            out.columns = out.columns.str.replace(" ", "_")
            
        except ValueError:
          
            self.log.exception("Dataframe empty: {}".format(tob.google_rl))
            
            out = pd.DataFrame({'date': []})
        
        self.data = out
        
        if save == True:
            # save
            self.save_data(out)
            
        else:
          
            return out
            
    def get_info(self, glist, save = True):
        
        tdict = {}
        
        for g in glist:
            
            try:
            
                i = "".join(["g_", g]).replace(" ", "_")
                
                name = "".join(["Google Search: ", g])
                
                u = g.replace(" ", "%20")
                
                category = "Search term in US"
                
                updated = str(datetime.datetime.now().strftime("%b %#d, %Y %#I:%M %p"))
                
                citation = "".join(["Google Trends", ", [", name, "], ", "retrieved from Google Trends", 
                                    ", ", "https://www.google.com/trends", ", ", str(datetime.datetime.now().strftime("%b %#d, %Y"))])
                                    
                link = "https://trends.google.com/trends/explore?q={}&geo=US-WA-819".format(u)
                
                tdict[i] = {"name": name, "code": g, "updated": updated, "category": category, 
                            "citation": citation, "link": link}
            except:
                
                self.log.exception("No info found for {}".format(g))
                
        self.info = tdict
            
        if save == True:
            
            self.save_info(tdict)
                
        else:
            
            return(tdict)
            
    def collect(self, glist, save = True):
        
        self.get_csv(glist = glist, save = save)
        
        self.get_info(glist = glist, save = save)

def collect_data(stocklist, fredpairs, glist, search_lower = None, search_upper = None, save = True):
    
    s = stocks(search_lower = search_lower, search_upper=search_upper)
    s.get_csv(stocklist, save = save)
    
    f = fred(search_lower = search_lower, search_upper=search_upper)
    f.get_csv(fredpairs, save = save)
    
    t = trends(search_lower = search_lower, search_upper=search_upper)
    t.get_csv(glist, save = True)
    
def collect_info(stocklist, fredpairs, glist, search_lower = None, search_upper = None, save = True):
  
    s = stocks(search_lower = search_lower, search_upper=search_upper)
    s.get_info(stocklist, save = save)
    
    f = fred(search_lower = search_lower, search_upper=search_upper)
    f.get_info(fredpairs, save = save)
    
    t = trends(search_lower = search_lower, search_upper=search_upper)
    t.get_info(glist, save = save)


# 
# 
# kw_list = glist[0]
# 
# tob.build_payload(kw_list = [keyword], cat = 0,
#                   timeframe = " ".join(["2010-01-01", "2023-01-01"]),
#                   geo = 'US-WA-819')
#  
# df = tob.interest_over_time()
# 
# import pandas as pd
# from pytrends.request import TrendReq
# 
# pytrend = TrendReq(hl='en-US', tz=360, timeout=(10,25), retries=2, backoff_factor=0.1)
# 
# #pytrend = TrendReq(hl='en-US', tz=360)
# 
# # pytrend.build_payload(
# #      kw_list= ["used cars"],
# #      timeframe = " ".join(["2009-01-01", "2023-01-01"])
# #      #geo='US-WA-819',
# #      #gprop=''
# #      )
# #      
# pytrend.build_payload(
#      kw_list= ['used car near me'],
#      timeframe = "2016-01-01 2023-01-01"
#      )
# 
# 
# data = pytrend.interest_over_time()
# 
# data[data['cars'] > 0]
# 
# 
# 
# 
# 
# for index, (kw, geo) in enumerate(product([kw_list], "US-WA-819")):
#   print(index, kw, geo)
#   
# from itertools import product
#   
#   
# 
# from pytrends.exceptions import ResponseError, TooManyRequestsError, Timeout
# import pytrends
# import time
# time.sleep(240)
# 
# pytrend = TrendReq()
# 
# #provide your search terms
# kw_list=['Facebook']
# 
# #search interest per region
# #run model for keywords (can also be competitors)
# pytrend.build_payload(kw_list, timeframe='today 1-m')
# 
# # Interest by Region
# regiondf = pytrend.interest_over_time()
# 
# 
# 
# 
# full = pd.DataFrame()
# trends_list = ['sunscreen']
# for x in trends_list:
#   
#   # try a max of 2 times for each keyword
#   n_retrys = 0
#   while n_retrys < 2:
#     
#     try:
#       pytrend.build_payload(
#          kw_list= [x],
#          cat = 0,
#          timeframe = " ".join(["2009-01-01", "2023-01-01"]),
#          gprop=''
#          )
#     
#       data = pytrend.interest_over_time()
#       
#     except TooManyRequestsError:
#       print("too many requests")
#       
#       time.sleep(60)
#       
#       # log.info("Too many requests")
#     except: ResponseError:
#       print("Unknown Response Error, skipping {}".format(x)):
#     
#       continue
#     
#     n_retrys += 1
#     
#   # allow no more than 3 0s
#   if data.empty or (data == 0).sum()[x] > 3:
#     
#     print("Incomplete data for {}".format(x))
#     continue
#   
#   else:
#     data = data.drop(labels = ['isPartial'], axis = 'columns')
#                         
#     full.append(data)
#     
#     print("{} data recieved".format(glist[x]))
#     
#     
# (data == 0).sum()['used cars']
# 
# data.empty
# 
# 
# 
# pytrend = TrendReq()
# pytrend.build_payload(kw_list=['used car'], timeframe= " ".join(["2009-01-01", "2023-01-01"]), geo = 'US-WA-819')
# 
# # pytrend.build_payload(kw_list=['crust', 'dummy'], timeframe=['2022-09-04 2022-09-10', '2022-09-18 2022-09-24'], geo = 'US-WA-819')
# time.sleep(60)
# 
# #get today's treniding topics
# data = pytrend.interest_over_time()
# 
# #TooManyRequestsError
# # use verbose=True for print output


# import pandas as pd

# df = pd.read_csv("data/in/stocks.csv")
# df.iloc[:, 0]
# df.loc['date']
# df['date'] = pd.to_datetime(df['date']).to_period('M')
# a = pd.to_datetime(df['date'])
# a.to_period('M')
