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
                scoring,
                top_features,
                  data_dir:str = "data/out/features.csv",
                  targetvar:str = 'n',
                  max_depth = np.arange(2, 6, 1),
                  verbose = 0):
    """
    Performs random forest regression on 5-fold CV for file in data_dir.
    CV on max_depth
    Returns list of features by permutation importance.
    """
    data = pd.read_csv(data_dir)

    X, y = data.drop(columns = targetvar), data[targetvar]
        
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', RandomForestRegressor(random_state = 25,
                                        bootstrap=False,
                                        max_features="sqrt",
                                        n_estimators=250)
        )
    ])
    
    search = GridSearchCV(pipeline, 
                          {'model__max_depth':max_depth},
                           cv = 5,
                           scoring = scoring,
                           verbose = verbose)
                          
    search.fit(X_train, y_train)
                               
    from sklearn.inspection import permutation_importance
    import time
    
    start_time = time.time()
    
    # get feature importances with fitted regressor
    result = permutation_importance(
        search, X_test, y_test, n_repeats=10, random_state=1933, n_jobs=-1
    )
    
    elapsed_time = time.time() - start_time
    
    if verbose > 0:
        print(f"Elapsed time to compute the importances: {elapsed_time:.3f} seconds")

    forest_importances = pd.Series(result.importances_mean, index=search.feature_names_in_).sort_values(ascending = False)
    
    out = forest_importances.index[:top_features]
    
    return list(out)
    
    