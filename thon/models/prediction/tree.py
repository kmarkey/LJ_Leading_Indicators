import os
import re
import numpy as np
import pandas as pd
from pandas import DataFrame
from sklearn.tree import DecisionTreeRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import GridSearchCV
from thon.churn_functions import modernize, simple_split, bake
import warnings

# do cv and fit with cost-complexity pruning
def decision_tree(data,
                  split,
                  feature_selection = None,
                  targetvar:str = 'n'):
    
    np.random.seed(1933)
    
    """
    Creates a decision tree with optimized cost-complexity pruning for file in data_dir.
    Saves and returns complete df
    """

    if feature_selection is not None:
        X, y = data[list(feature_selection)], data[targetvar]
    else:
        X, y = data.drop(columns = targetvar), data[targetvar]
        
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    # cv
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', DecisionTreeRegressor(max_depth = len(X_train.columns)))
        ])
    
    pipeline.fit(X_train, y_train)
    
    pred_train = pd.Series(pipeline.predict(X_train), index=X_train.index)
    pred_test = pd.Series(pipeline.predict(X_test), index=X_test.index)
    
    pred = pipeline.predict(modernize(X_train))
    
    out = bake(y_train, y_test, pred_train, pred_test, pred)
    
    # save diagram
    #     tree.plot_tree(model[1])
    #     out_file = "thon/models/figs/tree.dot", feature_names = list(X_train))
        
    return out