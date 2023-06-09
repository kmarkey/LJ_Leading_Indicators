# takes feature importance df and path to complete feature dictionary to get testing data for model
# Currently naming cols with incorrect lag for model ingestion
import numpy as np
import pandas as pd
import os
import pickle
import re
import warnings
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.pipeline import Pipeline
import sklearn.tree as tree
import random

def simple_split(X, y, n):
    
    if type(n) is tuple and len(n) == 2:
        a1, a2, b1, b2 = 0, n[0], n[1], len(X.index)
    elif type(n) is tuple and len(n) == 4:
        a1, a2, b1, b2 = n[0], n[1], n[2], n[3]
    else:
        a1, a2, b1, b2  = 0, n, n, len(X.index)
    
    # select rows
    X_train, y_train = X[a1:a2], y[a1:a2]
    X_test, y_test = X[b1:b2], y[b1:b2]
    
    return X_train, X_test, y_train, y_test

# get list of features from each model and return features without a lag
def modernize(feature_list, complete_path = "./data/out/complete.csv", supp_path = "./data/out/supp_ext.csv", ahead = 3):
    
    complete = pd.read_csv(complete_path)
    
    supp = pd.read_csv(supp_path)
    
    slist = []
    
    for f in feature_list:
            
        # get seasonal cols first
        if f in list(supp.columns):
            
            x = supp[f]
            
        elif f in list(complete.columns):
        
            x = complete[f.split("_lag")[0] + "_lag" + str(pd.to_numeric(re.sub(r".*_lag", "", f)) - ahead)].tail(ahead)
            
            # rename feature name
            x.name = f
            
            x = x.reset_index(drop = True)
              
        else:
            
            print("{} not found".format(f))
            break
            
        slist.append(x)
        
    return pd.concat(slist, axis = 1)

# saves model with pickle, no metadata
def save_model(mod, filename):
    with open("models/" + filename, 'wb') as file:
        pickle.dump(mod, file)
    
# quick and dirty plotting and metric
def out_eval(data, metric, verbose = 0):
    """
    Comptutes metric on data. Verbositycan be an integer from 0-2 with 0 as no output, 1 as printed output, and 2 including plots
    """
    
    # split data
    train = data[data['group'] == 'train']
    test = data[data['group'] == 'test']
    pred = data[data['group'] == 'pred']
    
    train_metric = metric(train['actual'], train['pred'])
    test_metric = metric(test['actual'], test['pred'])
    
    if verbose > 1:
        plt.plot(train['actual'], 'g')
        plt.plot(train['pred'], 'g--')
        plt.plot(test['actual'], 'b')
        plt.plot(test['pred'], 'b--')
        plt.plot(pred['pred'], 'r')
        
    if verbose > 0:
        return (train_metric, test_metric)
    
def bake(y_train, y_test, pred_train, pred_test, pred):
    
    train = pd.DataFrame({'actual': y_train, 'pred': pred_train, 'group': 'train'})
    
    test = pd.DataFrame({'actual': y_test, 'pred': pred_test, 'group': 'test'})
    
    pred = pd.DataFrame({'actual': np.nan, 'pred': pred, 'group': 'pred'})
    
    return pd.concat([train, test, pred], axis = 0, ignore_index = True)

