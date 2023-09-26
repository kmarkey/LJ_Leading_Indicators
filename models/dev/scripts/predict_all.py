import numpy as np
import pandas as pd
import os
import re
import warnings
from captum.attr import IntegratedGradients
from sklearn.linear_model import Lasso, LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.metrics import mean_squared_error
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.model_selection import GridSearchCV, KFold
from scripts.churn_functions import simple_split, bake, modernize, out_eval


from models.dev.scripts.linear import linear_regression
from models.dev.scripts.tree import decision_tree
from models.dev.scripts.random import random_forest
from models.dev.scripts.arima import arima
from models.dev.scripts.gru import gru
from models.dev.scripts.lstm import lstm

import torch
from torch.autograd import Variable 
from torch import nn


os.chdir('C:\\Users\\keato\\Documents\\LocalRStudio\\LJ_Leading_Indicators')


data = pd.read_csv("data/out/features.csv")


def run_predict(data = data, split = 135, ahead = 6, save = True, verbose = False, branch = "dev"):
    
    l = linear_regression()
    l.fit(data = data, 
                  split = split,
                  scoring = "neg_mean_squared_error",
                  feature_selection = True)

    l.predict(ahead = ahead)
    
    t = decision_tree()
    t.fit(data = data, 
                  split = split,
                  scoring = "neg_mean_squared_error",
                  feature_selection = True)

    t.predict(ahead = ahead)
    
    r = random_forest()
    # takes a little bit
    r.fit(data = data, 
                  split = split,
                  scoring = "neg_mean_squared_error",
                  feature_selection = True)

    r.predict(ahead = ahead)
    
    a = arima()
    a.fit(data = data, 
          split = split,
          feature_selection = True,order=(12, 1, 0)
         )
    
    a.predict(ahead = ahead)
    
    g = gru()
    g.fit(data = data, split = split, hidden_size= 32, num_epochs= 100, verbose = verbose)
    
    
    # get top 15 features
    gimp = g.get_importances(15, names = True)
    g.fit(data = data, split = split, hidden_size= 16, num_epochs= 250, feature_selection=gimp, verbose = verbose)
    g.predict(ahead = ahead)
    
    m = lstm()
    m.fit(data = data, split = split, hidden_size= 8, num_epochs= 150, verbose = verbose)
    m.predict(ahead = ahead)
    
    # always overwrite folder
    from datetime import date
    import shutil
    newpath = "models/" + branch + "/snapshots/" + str(date.today())
    
    if os.path.exists(newpath):
        shutil.rmtree(newpath)
    os.makedirs(newpath)
        
    if save == True:
        l.full.to_csv(newpath + "/l.csv")
        l.get_importances().to_csv(newpath + "/l-imp.csv")

        t.full.to_csv(newpath + "/t.csv")
        t.get_importances().to_csv(newpath + "/t-imp.csv")

        r.full.to_csv(newpath + "/r.csv")
        r.get_importances().to_csv(newpath + "/r-imp.csv")

        a.full.to_csv(newpath + "/a.csv")

        g.full.to_csv(newpath + "/g.csv")
        g.get_importances().to_csv(newpath + "/g-imp.csv")

        m.full.to_csv(newpath + "/m.csv")
        m.get_importances().to_csv(newpath + "/m-imp.csv")
    