from bs4 import BeautifulSoup
import requests
import json
from datetime import datetime as dt
import time

def fred_info(names_dict, save = True):
  
    tdict = {}
  
    for n in names_dict.keys():
        
        v = names_dict.get(n)
        
    # Define the URL of the webpage
        url = "https://fred.stlouisfed.org/series/{}".format(v)
    
    # Send a request to the webpage and retrieve the HTML response
        response = requests.get(url, timeout = 5)
    
    # Create a BeautifulSoup object from the HTML response
        try:
            soup = BeautifulSoup(response.text, 'html.parser')
    
    # Find the element that contains the suggested citation
            name = soup.find('span', {'id': 'series-title-text-container'}).text.strip()
            
            code = v
            
            updated = soup.find('span', {'class': 'updated-text'})['title']
            
            category = soup.find('a', {'class': 'note-release series-release fg-ext-link-gtm fg-release-link-gtm'}).text.strip()
            
            citation = soup.find('p', {'class': 'citation'}).text.strip().replace("\\s", "")

            tdict[n] = {"name": name, "code": code, "updated": updated, "category": category, 
                        "citation": citation, "link": url}
        except:
            
            print("Code {} not found".format(v))
            continue
          
    if save == True:
      
        with open("./data/out/fred_info.json", "w") as outfile:
            json.dump(tdict, outfile)
            
        print("File saved")
    else:
        return(tdict)
        
    # Print the suggested citation

fp = {"unemp": "UNRATE"}

fred_info(fp, save= False)


def stock_info(stocklist, save = True):
    
    tdict = {}
    
    for s in stocklist:
        
        url = "https://finance.yahoo.com/quote/{}/?p={}".format(s, s)
        
        response = requests.get(url, timeout = 5)
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        try:
        
            name = soup.find('h1', {"class": "D(ib) Fz(18px)"}).text.strip()
            
            code = s
            
            updated = str(dt.now().strftime("%b %#d, %Y %#I:%M %p"))
            
            category = "".join([soup.find(text = "Sector(s)").findNext('span').text, 
                               ", ",
                               soup.find(text = "Industry").findNext('span').text])
                               
            citation = "".join([name, ", [", code, "], ", "retrieved from Alpha Vantage Inc.", 
                                ", ", str(dt.now().strftime("%b %#d, %Y")), "."])
            
            tdict[s] = {"name": name, "code": code, "updated": updated, "category": category, 
                        "citation": citation, "link": url}
        except:
            
            print("Uh OH")
    
    if save == True:
      
        with open("./data/out/stock_info.json", "w") as outfile:
            json.dump(tdict, outfile)
            
        print("File saved")
    else:
        return(soup)

stock_info(["GM"], save = False)

def trends_info(kw_list, save = True):
    
    tdict = {}
    
    for k in kw_list:
        
        try:
        
            name = k.replace("_", " ")[2:]
            
            code = k
            
            category = "Search term in US-WA-819"
            
            updated = str(dt.now().strftime("%b %#d, %Y %#I:%M %p"))
            
            citation = "".join(["Google Trends", ", [", name, "], ", "retrieved from Google Trends", 
                                ", ", "https://www.google.com/trends", ", ", str(dt.now().strftime("%b %#d, %Y"))])
                                
            link = "https://trends.google.com/trends/explore?q={}&geo=US-WA-819".format(name)
    
            tdict[k] = {"name": name, "code": code, "updated": updated, "category": category, 
                            "citation": citation, "link": url}
        except:
            
            print("Uh OH")
    
    if save == True:
      
        with open("./data/out/trends_info.json", "w") as outfile:
            json.dump(tdict, outfile)
            
        print("File saved")
    else:
        return(tdict)

trends_info(["g_google"], save = False)
