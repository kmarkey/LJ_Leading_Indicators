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
            
            x.name = f
            
            x = x.reset_index(drop = True)
            
        else:
            
            print("{} not found".format(f))
                        
        slist.append(x)
        
    return pd.concat(slist, axis = 1)

# saves model with pickle, no metadata
def save_model(mod, filename):
    with open("models/" + filename, 'wb') as file:
        pickle.dump(mod, file)
        
# returns df of feature importance if model is a tree. will amend later for other model types
def tree_importance(model, cols, save = False):
    if hasattr(model, "feature_importances_"):
        imp = pd.DataFrame(model.feature_importances_,
                           index = cols,
                           columns = ['importance'])
    else:
        print("Model type not supported")

    if save == True:
        imp.to_csv("./data/out/treefeatures.csv")
    else:
        return imp
    
# quick and dirty plotting and mse
def plot_eval(prediction, actual):
    plt.plot(actual)
    plt.plot(prediction)
    mse = mean_squared_error(prediction, actual)
    
    print(mse)
    print(mse/len(prediction))
    
def bake(y_train, y_test, pred_train, pred_test, pred):
    
    train = pd.DataFrame({'pred': y_train, 'actual': pred_train, 'group': 'train'})
    
    test = pd.DataFrame({'pred': y_test, 'actual': pred_test, 'group': 'test'})
    
    pred = pd.DataFrame({'pred': pred, 'actual': np.nan, 'group': 'pred'})
    
    return pd.concat([train, test, pred], axis = 0)

