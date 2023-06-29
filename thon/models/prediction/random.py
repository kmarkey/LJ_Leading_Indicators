import numpy as np
import pandas as pd
import os
import re
import warnings
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import GridSearchCV
from sklearn.pipeline import Pipeline
import random
from thon.churn_functions import modernize, bake, simple_split


def random_forest(data,
                  split,
                  feature_selection = None,
                  targetvar:str = 'n'):
        
    if feature_selection is not None:
        X, y = data[list(feature_selection)], data[targetvar]
    else:
        X, y = data.drop(columns = targetvar), data[targetvar]
        
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', RandomForestRegressor(random_state = 25,
                                        bootstrap=False,
                                        max_features="sqrt",
                                        n_estimators=250,
                                        max_depth = 3)) # was cv
    ])
    
        pipeline.fit(X_train, y_train)
    
    pred_train = pd.Series(pipeline.predict(X_train), index=X_train.index)
    pred_test = pd.Series(pipeline.predict(X_test), index=X_test.index)
    
    pred = pipeline.predict(modernize(X_train))
    
    out = bake(y_train, y_test, pred_train, pred_test, pred)
    
    return out
    
    