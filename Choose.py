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
from sklearn.linear_model import Lasso, Ridge
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import GridSearchCV, train_test_split

#----------------
os.chdir('C:\\Users\\keato\\Documents\\LocalRStudio\\LJ_Leading_Indicators')
#------------------

def choose_features(path, cv_range = (0, 5), scale = True, save = True):
    data = pd.read_csv(path)

    X, y = data.drop(columns = ['n']), data['n']
    
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
                      {'model__alpha':np.arange(cv_range[0], cv_range[1], 0.5)},
                      cv = 5,
                      scoring = 'neg_mean_squared_error',
                      verbose = 3)
    search.fit(X, y, )
    
    coef = search.best_estimator_[1].coef_
    out = X.iloc[:, coef != 0]
    out.columns
    out.insert(0, 'n', y, True)
    out.insert(0, 'month', X['month'], True)
    
    if save == True:
        out.to_csv("data/out/lasso.csv")
        
        return print('lasso.csv (', len(out), ', ', len(out.columns), ') saved! \n', 
                     search.best_params_, sep = '')
    else:
        return out

choose_features("data/out/features.csv", cv_range = (0, 5), save = True)