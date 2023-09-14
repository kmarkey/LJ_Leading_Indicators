import numpy as np
import pandas as pd
import os
import re
import warnings
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import GridSearchCV, KFold
from sklearn.pipeline import Pipeline
import random
from scripts.churn_functions import simple_split


def rf_features(split,
                scoring,
                top_features,
                  data_dir:str = "data/out/features.csv",
                  targetvar:str = 'n',
                  max_depth = np.arange(2, 6, 1),
                  verbose = 0):
    """
    Performs random forest regression on 5-fold CV on max_depth for file in data_dir.
    Ranks by permutation feature importance.
    Returns n top_features.
    """
    data = pd.read_csv(data_dir)

    X, y = data.drop(columns = targetvar), data[targetvar]
        
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', RandomForestRegressor(random_state = 1933,
                                        bootstrap=False,
                                        max_features="sqrt",
                                        n_estimators=250)
        )
    ])
    
    cv = KFold(n_splits=5, shuffle=True, random_state=1933)
    
    search = GridSearchCV(pipeline, 
                          {'model__max_depth':max_depth},
                           cv = cv,
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
    
    