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


def random_perm(split,
                  data_dir:str = "data/out/features.csv",
                  targetvar:str = 'n',
                  verbose = 0):
    
    data = pd.read_csv(data_dir)

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
    
    from sklearn.inspection import permutation_importance
    import time
    
    start_time = time.time()
    
    result = permutation_importance(
        pipeline, X_test, y_test, n_repeats=10, random_state=1933, n_jobs=-1
    )
    
    elapsed_time = time.time() - start_time
    
    if verbose > 0:
        print(f"Elapsed time to compute the importances: {elapsed_time:.3f} seconds")

    forest_importances = pd.Series(result.importances_mean, index=pipeline.feature_names_in_)
    
    out = forest_importances[forest_importances > 0].index
    
    return out.tolist()
    
    