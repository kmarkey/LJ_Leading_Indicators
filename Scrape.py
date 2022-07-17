# -*- coding: utf-8 -*-
"""
Created on Fri Jun  3 20:07:31 2022

@author: keato
"""

# free stock data with alpha vantage
import requests
import os
import pandas as pd
import json

os.chdir('C:/Users/keato/Documents/LocalRStudio/LJ_Leading_Indicators')

# replace the "demo" apikey below with your own key from https://www.alphavantage.co/support/#api-key
key = 'NPN0X4RFKGIJ5XU5'
tick = 'GM'

url = str('https://www.alphavantage.co/query?function=TIME_SERIES_MONTHLY&symbol=' + tick + '&apikey=' + key)

r = requests.get(url)
tdict = r.json()
jdict = json.dumps(tdict, indent = 4)

with open("sample.json", "w") as outfile:
    json.dump(tdict, outfile)

ata = pd.read_json(url)
#df = pd.DataFrame.from_dict(data)

new_df = pd.concat([pd.DataFrame(pd.json_normalize(x)) for x in df['Monthly Time Series']], ignore_index=True)
print(data)
pd.DataFrame(pd.json_normalize(x))


#########json_normalize
r = requests.get(url)
tdict = r.json()
pth = os.path.join("/data/jdat")
json.dump(tdict, fp = pth)

data = pd.read_json(url)
json
with open(url,'r') as f:
    data = json.loads(f.read())
 
for x in df['Monthly Time Series']:
    print(x)

# df = pd.read_json(url)['Monthly Time Series']
with open()
with open("/data.json") as f:
    data = json.loads(f.read())
    

headers = {'Authentication' : 'NPN0X4RFKGIJ5XU5'}
response = requests.get(url = url, headers = headers)
df = response.json()

    
df = pd.json_normalize(data, record_path = ['Monthly Time Series'])

for i in df['Monthly']:
    print(i)
os.PathLike(r)
print(data)
