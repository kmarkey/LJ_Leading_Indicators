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

def rollover(feature_importance_df, complete_path = "./data/out/complete.csv", ahead = 3):
    
    complete = pd.read_csv(complete_path)
    
    impidx = feature_importance_df[feature_importance_df["importance"] != 0].index
    names = []
    for i in list(impidx):
        if i not in ["month", "bin", "mnum"]:
            names.append(i.split("_lag")[0] + "_lag" + str(pd.to_numeric(re.sub(r".*_lag", "", i)) - ahead))
        
    important = complete.filter(names) #### 
    important.columns = (x for x in list(impidx) if x not in ["month", "bin", "m_num"]) #### AHHHHH BAD
    important = important.tail(ahead)
    important.set_axis(np.arange(ahead), inplace = True)
    
    warnings.warn("Features are named incorrectly, they are led 3 months ahead of their label")
    
    # add unimportant names back with empty values
    unimpidx = list(set(feature_importance_df.index).difference(impidx))
    dummy = pd.DataFrame(0, index=np.arange(len(important)), columns=unimpidx).tail(ahead)
    dummy.set_axis(np.arange(ahead), inplace = True)
    
    supp = pd.read_csv("./data/out/suppl.csv")
    supp.set_axis(list(dummy.index), inplace = True)
    
    if ("bin" in list(impidx)) & ("month" in list(impidx)):
        out = pd.concat([important, dummy, supp], axis = 1).tail(ahead)
    elif "bin" in list(impidx):
        supp = supp[["bin"]]
        out = pd.concat([important, dummy, supp], axis = 1).tail(ahead)
    elif "month" in list(impidx):
        supp = supp[["month"]]
        out = pd.concat([important, dummy, supp], axis = 1).tail(ahead)
    else: 
        out = pd.concat([important, dummy]).tail(ahead)

    # reorder cols
    out = out[list(feature_importance_df.index)]

    return(out)

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
    
def bake_pred(train_y, test_y, pred_y):
    train_y = pd.DataFrame(train_y, columns = ['n'])
    train_y['group'] = 'train'
    test_y = pd.DataFrame(test_y, columns = ['n'])
    test_y['group'] = 'test'
    pred_y = pd.DataFrame(pred_y, columns = ['n'])
    pred_y['group'] = 'pred'
    
    out = pd.concat([train_y, test_y, pred_y], axis = 0, ignore_index=True)
    return(out)

