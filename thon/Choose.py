# -*- coding: utf-8 -*-
"""
Created on Thu Sep 22 18:53:54 2022

@author: keato
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import sklearn
from sklearn.linear_model import Lasso
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import GridSearchCV

#----------------
# os.chdir('C:\\Users\\keato\\Documents\\LocalRStudio\\LJ_Leading_Indicators')
#------------------

def choose_features(path, targetvar= 'n', alpha_range = (0, 5), scale = True, save = True):
    data = pd.read_csv(path)

    X, y = data.drop(columns = [targetvar]), data[targetvar]
    
    if scale == True:
        pipeline = Pipeline([
            ('scaler', StandardScaler()),
            ('model', Lasso())
        ])
    else:
        pipeline = Pipeline([
            ('model', Lasso())
        ])
    
    search = GridSearchCV(pipeline,
                      {'model__alpha':np.arange(alpha_range[0], alpha_range[1], 0.5)},
                      cv = 10,
                      scoring = 'neg_mean_squared_error') # no stdout
    search.fit(X, y)
    
    coef = search.best_estimator_[1].coef_
    out = X.iloc[:, coef != 0]

    out.insert(0, targetvar, y, True)
    
    print("Alpha estimate:", search.best_params_)
    
    if save == True:
        out.to_csv("./data/out/lasso.csv")
        print('lasso.csv (', len(out), ', ', len(out.columns), ') saved! \n', search.best_params_, sep = '')
    else:
        print(len(out.columns), 'features selected \n', sep = ' ')
        return out