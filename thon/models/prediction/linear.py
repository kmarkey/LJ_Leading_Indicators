import numpy as np
import pandas as pd
import os
import re
import warnings
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error
from sklearn.pipeline import Pipeline
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import GridSearchCV

from thon.churn_functions import modernize, bake, simple_split

def linear_model(
    data,
    split,
                 feature_selection = None,
                 targetvar:str = 'n'):
    """
    Runs linear regression with optional feature selection on file in data_dir
    """
    
    if feature_selection is not None:
        X, y = data[list(feature_selection)], data[targetvar]
    else:
        X, y = data.drop(columns = targetvar), data[targetvar]
        
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    model = make_pipeline(StandardScaler(), 
                          LinearRegression())

    # Train the model
    model.fit(X_train, y_train)
    
    # Store the fitted values as a time series with the same time index as
    # the training data
    train_pred = pd.Series(model.predict(X_train), index= X_train.index)
    
    test_pred = pd.Series(model.predict(X_test), index = X_test.index)
    
    X_modern = modernize(list(X_train.columns))
    
    pred = model.predict(X_modern)
    
    out = bake(y_train, y_test, train_pred, test_pred, pred)
    
    return out
    