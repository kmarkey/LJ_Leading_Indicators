import os
import re
import numpy as np
import pandas as pd
from pandas import DataFrame
from sklearn import tree
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import GridSearchCV
from thon.churn_functions import modernize, simple_split, bake
import warnings

# do cv and fit with cost-complexity pruning
def trim_tree(split,
                  scoring,
                  data_dir:str = "data/out/features.csv",
                  targetvar:str = 'n',
                  depth_range = np.arange(2, 8, 1),
                  verbose = 0):
    
    np.random.seed(1933)
    
    """
    Creates a decision tree with optimized cost-complexity pruning for file in data_dir.
    Saves and returns complete df
    """
    data = pd.read_csv(data_dir)

    # Training data
    X, y = data.drop(columns = targetvar), data[targetvar]
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    # cv
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', tree.DecisionTreeRegressor())
        ])
    
    search = GridSearchCV(pipeline,
                      {'model__max_depth':depth_range},                      
                      cv = 5,
                      scoring = scoring,
                      verbose = verbose)
    
    search.fit(X_train, y_train)
    
    if verbose > 0:
        print(search.best_params_)
    
    # train
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', tree.DecisionTreeRegressor(max_depth=search.best_params_['model__max_depth']))    
        ])
    
    model = pipeline.fit(X_train, y_train)
    
    imp = X_train.columns[model.named_steps['model'].feature_importances_ > 0]
    
    return imp.tolist()