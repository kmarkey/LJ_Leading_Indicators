# manage stock data:
import os
import requests
import json
import pandas as pd
import re
from thon.config import config_logger
from datetime import date, datetime as dt
import time
from alpha_vantage.timeseries import TimeSeries # AV
import pandas_datareader as pdr # access fred
import webbrowser
from pytrends.exceptions import ResponseError
from pytrends.request import TrendReq # google trends
from bs4 import BeautifulSoup


class manager:
    
    def __init__(self, keyname, keypath = "./keys/keys.txt", boundpath = "./keys/bounds.csv", data_class = None):
        
        self.log = config_logger("./logs/my_log_" + str(date.today()) + ".log")
        
        self.key = self.__get_key__(keyname = keyname, keypath = keypath)
        
        self.search_lower, self.search_upper = self.__bounds__(boundpath)
        
        self.data_class = data_class
        
        self.data_path = os.path.join(os.getcwd(), "./data/in/{}.csv".format(self.data_class))
        
        self.exist = pd.read_csv(self.data_path)
        
    def __bounds__(self, boundpath):
        
        try:
          
            file = pd.read_csv(os.path.join(os.getcwd(), boundpath)).to_dict(orient = 'list')
            
            lower = str(file.get("search_bottom")[0])
          
            upper = str(file.get("search_top")[0])
            
            self.log.debug("Lower bound set to: {l} and upper bound set to {u}".format(l = lower, u = upper))
            
            return lower, upper
    
        except FileNotFoundError:
            self.log.exception("Bounds file not found")
          
        except:
            self.log.exception("Bounds file formatted incorrectly")
            
    def __get_key__(self, keyname, keypath):
      
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
        
        else:
          
            self.log.error("Error getting keys")
            
            return None
    
    @property
    def recyclable(self):
        
        if (dt.strptime(self.search_lower, "%Y-%m-%d").month >= dt.strptime(self.exist["date"].min(), "%Y-%m-%d").month and
            dt.strptime(self.search_lower, "%Y-%m-%d").year >= dt.strptime(self.exist["date"].min(), "%Y-%m-%d").year and
            dt.strptime(self.search_upper, "%Y-%m-%d").month <= dt.strptime(self.exist["date"].max(), "%Y-%m-%d").month and
            dt.strptime(self.search_upper, "%Y-%m-%d").year <= dt.strptime(self.exist["date"].max(), "%Y-%m-%d").year and
            len(self.food) <= self.exist.shape[1] - 1):
             
            return True
            
        else:
            
            return False #test
            
    def save_data(self, out):
        
        out.to_csv(self.data_path, index = False)
        
        self.log.info("".join(["{}.csv size: ".format(self.data_class), out.shape, ", saved!"]))
        
        return
        
    def save_info(self, info):
        
        with open("./data/out/{}_info.json".format(self.data_class), "w") as outfile:
            json.dump(info, outfile)
            
        self.log.info("".join(["{}_info.json saved!".format(self.data_class)]))
        
        return

class stocks(manager):
    
    def __init__(self, keyname = "alphavantage_key", data_class = "stocks"):
        
        super().__init__(keyname = keyname, data_class = data_class)
        
    def get_csv(self, stocklist, save = True):
      
        self.food = stocklist
        
        if self.recyclable == True and save == False:
            
            self.log.info("{name}.csv, size:{dim}, will be reused!".format(name = self.data_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return self.data
            
        if self.recyclable == True and save == True:
            
            self.log.info("{name}.csv, size: {dim}, can be reused! Leaving {name}.csv untouched".format(name = self.data_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return
            
        else:
            
        # trim first of month
            def trim_fom(df):
                # always date
                try:
                    
                    df['date'] = pd.to_datetime(df['date']).dt.to_period('M').dt.to_timestamp()
                    
                    df = df.query('@self.search_lower <= `date` & `date` <= @self.search_upper')
                    
                except:
                    
                    self.log.info("Column date not found")
                
                return df
                    
            def cleaner(df, tick):
                
                out = (df.sort_index(ascending = True)
                            .reset_index()
                            .rename({'4. close': '{}'.format(tick), 
                                     '5. volume': '{}_v'.format(tick)}, 
                                    axis = 'columns')
                            .loc[:, ['date', '{}'.format(tick), '{}_v'.format(tick)]]
                            .pipe(trim_fom))
                            
                return out
                
            out = pd.DataFrame(columns = ['date'])
            
            ts = TimeSeries(key = self.key, output_format = "pandas")
        
            for tick in stocklist:
              
                try:
                    
                    data, metadata = ts.get_monthly(symbol = tick)
                    
                    data = cleaner(df = data, tick = tick)
                    
                except ValueError:
                  
                    log.exception("{} is not a valid API call and will be excluded".format(tick))
                    
                    continue
            
                out = out.merge(data, on = 'date', how = 'outer')
                
                if self.food.index(tick) % 5 == 4: # avoid AV timeout every 5
                    
                    self.log.info("Sleeping for 60s to avoid AlphaVantage timeout")
                    
                    time.sleep(60)
                    
                out = out.sort_values(by = 'date', ascending = True, ignore_index = True)
                
            self.data = out
            
            if save == True:
                # save
                self.save_data(out)
                
            else:
              
                return out
                
    def get_info(self, stocklist, save = True):
        
        tdict = {}
        
        for s in stocklist:
          
            url = "https://finance.yahoo.com/quote/{}".format(s)
                    
            response = requests.get(url, timeout = 10)
            
            if response.status_code == 404:
                
                headers = {"User-Agent": "Chrome/71.0.3578.98"}
                
                response = requests.get(url, headers = headers, timeout = 10)
                
            soup = BeautifulSoup(response.text, 'html.parser')
                
            try:
                
                name = soup.find('h1', {"class": "D(ib) Fz(18px)"}).text.strip()
            
            except:
                
                name = None
                
                self.log.info("Could not find name for {}".format(s))
                
            code = s
            
            updated = str(dt.now().strftime("%b %#d, %Y %#I:%M %p"))
            
            try:
                
                category = "".join([soup.find(text = "Sector(s)").findNext('span').text, 
                                   ", ",
                                   soup.find(text = "Industry").findNext('span').text])
                
            except:
                
                category = None
                
                self.log.info("Could not find category for {}".format(s))
                
            citation = "".join([name, ", [", code, "], ", "retrieved from Alpha Vantage Inc.", 
                                ", ", str(dt.now().strftime("%b %#d, %Y")), "."])
            
            tdict[s] = {"name": name, "code": code, "updated": updated, "category": category, 
                        "citation": citation, "link": url}
            
        self.info = tdict
        
        if save == True:
            
            self.save_info(tdict)
            
            return
            
        else:
            
            return tdict
          
    def collect(self, stocklist, save = True):
        
        self.get_csv(stocklist = stocklist, save = save)
        
        self.get_info(stocklist = stocklist, save = save)
        
        return

class fred(manager):
    
    def __init__(self, keyname = "fred_key", data_class = "fred"):
        
        super().__init__(keyname = keyname, data_class = data_class)
        
    def get_csv(self, fredpairs, save = True):
        
        self.rev = {v: k for k, v in fredpairs.items()}
        
        self.food = list(fredpairs.values())
        
        self.names = list(fredpairs.keys())
        
        if self.recyclable == True and save == False:
            
            self.log.info("{name}.csv, size:{dim}, will be reused!".format(name = self.data_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return self.data
        
        if self.recyclable == True and save == True:
            
            self.log.info("{name}.csv, size: {dim}, can be reused! Leaving {name}.csv untouched".format(name = self.data_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return
            
        else:
          
            try:
                
                df = pdr.DataReader(self.food, self.data_class, self.search_lower, self.search_upper, api_key = self.key)
                
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
        
        for k, v in fredpairs.items():
            
        # Define the URL of the webpage
            url = "https://fred.stlouisfed.org/series/{}".format(v)
        
        # Send a request to the webpage and retrieve the HTML response
            response = requests.get(url, timeout = 5)
        
        # Create a BeautifulSoup object from the HTML response
            try:
                soup = BeautifulSoup(response.text, 'html.parser')
        
        # Find the element that contains the suggested citation
                name = soup.find('span', {'id': 'series-title-text-container'}).text.strip()
                
                updated = soup.find('span', {'class': 'updated-text'})['title']
                try:
                    
                    category = soup.find('a', {'class': 'note-release series-release fg-ext-link-gtm fg-release-link-gtm'}).text.strip()
                
                except:
                    
                    category = soup.find('p', {'class': 'col-xs-12 col-md-6 pull-left'}).text.strip().replace("  ", "").split("\n")[1]
                    
                citation = soup.find('p', {'class': 'citation'}).text.strip().replace("  ", "").replace("\n", " ")
                
                tdict[k] = {"name": name, "code": v, "updated": updated, "category": category, 
                            "citation": citation, "link": url}
            except:
                
                self.log.info("Fred code {} not found".format(v))
                
                continue
                
        self.info = tdict
        
        if save == True:
            
            self.save_info(tdict)
            
        else:
            
            return tdict
            
    def collect(self, fredpairs, save = True):
        
        self.get_csv(fredpairs = fredpairs, save = save)
        
        self.get_info(fredpairs = fredpairs, save = save)

class trends(manager):
    
    def __init__(self, keyname = "google_usr", data_class = "trends"):
        
        super().__init__(keyname = keyname, data_class = data_class)
        
    def get_csv(self, glist, save = True):
    
        self.food = glist
        
        self.data = []
        
        # setup trend obj
        
        tob = TrendReq(hl='en-US', timeout=(10), tz=480, retries = 2, backoff_factor = 0.1)
        
        n_tries = 0
        
        if tob.google_rl != None:
            
            self.log.info("Google rate Message: {}".format(tob.google_rl))
            
        if self.recyclable == True and save == False:
            
            self.log.info("{name}.csv, size:{dim}, will be reused!".format(name = self.data_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return self.data
        
        if self.recyclable == True and save == True:
            
            self.log.info("{name}.csv, size: {dim}, can be reused! Leaving {name}.csv untouched".format(name = self.data_class, dim = self.exist.shape))
            
            self.data = self.exist
            
            return
          
        while n_tries < 3:
            
            try:
                
                for x in range(len(glist)):
                  
                    keyword = [glist[x]]
                    
                    tob.build_payload(kw_list = keyword, cat = 0,
                                      timeframe = " ".join([self.search_lower, self.search_upper]),
                                      geo = 'US-WA-819')
                     
                    df = tob.interest_over_time()
                     
                    if not df.empty:
                        
                        df = df.drop(labels = ['isPartial'], axis = 'columns')
                          
                        self.data.append(df)
                        
                        self.log.debug("{} data recieved".format(glist[x]))
                        
                    if df.empty:
                        
                        self.log.info("{} not found. Continuing.".format(glist[x]))
                        
                break       
                
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
                
                category = "Search term in US-WA-819"
                
                updated = str(dt.now().strftime("%b %#d, %Y %#I:%M %p"))
                
                citation = "".join(["Google Trends", ", [", name, "], ", "retrieved from Google Trends", 
                                    ", ", "https://www.google.com/trends", ", ", str(dt.now().strftime("%b %#d, %Y"))])
                                    
                link = "https://trends.google.com/trends/explore?q={}&geo=US-WA-819".format(u)
                
                tdict[i] = {"name": name, "code": g, "updated": updated, "category": category, 
                                "citation": citation, "link": url}
            except:
                
                self.log.info("No info found for {}".format(g))
                
        if save == True:
          
            self.save_info(tdict)
                
        else:
            
            return(tdict)
            
    def collect(self, glist, save = True):
        
        self.get_csv(glist = glist, save = save)
        
        self.get_info(glist = glist, save = save)

def collect_all(stocklist, fredpairs, glist):
    
    s = stocks()
    s.collect(stocklist, save = True)
    
    f = fred()
    f.collect(fredpairs, save = True)
    
    t = trends()
    t.collect(glist, save = True)

collect_all(stocklist = stocklist, fredpairs = fredpairs, glist = glist)

# 
# 
# url = "https://fred.stlouisfed.org/series/T10YIEM"
# 
# response = requests.get(url, timeout = 5)
# 
# soup = BeautifulSoup(response.text, 'html.parser')
# 
# name = soup.find('span', {'id': 'series-title-text-container'}).text.strip()
# name       
# updated = soup.find('span', {'class': 'updated-text'})['title']
# updated
# 
# category = soup.find('p', {'class': 'col-xs-12 col-md-6 pull-left'}).text.strip()#.replace("\n", "").replace(" +" , " ")
# category = soup.find('p', {'class': 'col-xs-12 col-md-6 pull-left'}).text.strip().replace("  ", "").split("\n")[1]
# soup.find('div', {"class": "clearfix"}).findPrevious()
# category
# soup.
# 
# citation = soup.find('p', {'class': 'citation'}).text.strip().replace("  ", "").replace("\n", " ")
# citation
# 
# for a in citation:
#     print(ord(a))
# 
# re.sub(" +", " ", citation)
# 
# citation.encode("unicode_escape")
# tdict[k] = {"name": name, "code": v, "updated": updated, "category": category, 
#             "citation": citation, "link": url}
# url = "https://finance.yahoo.com/quote/LEA"
# 
# headers = {"User-Agent": "Chrome/71.0.3578.98"}
# 
# response = requests.get(url, timeout = 5)
# response.status_code
# 
# soup = BeautifulSoup(response.text, 'html.parser')
# 
# name = soup.find('h1', {"class": "D(ib) Fz(18px)"}).text.strip()
# 
# name
# updated = str(dt.now().strftime("%b %#d, %Y %#I:%M %p"))
# 
# category = "".join([soup.find(text = "Sector(s)").findNext('span').text,
#                               ", ",
#                               soup.find(text = "Industry").findNext('span').text])
# 
# citation = "".join([name, ", [", code, "], ", "retrieved from Alpha Vantage Inc.",
#                     ", ", str(dt.now().strftime("%b %#d, %Y")), "."])
# 
#               

