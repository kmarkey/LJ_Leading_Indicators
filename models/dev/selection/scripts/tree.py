import os
import re
import numpy as np
import pandas as pd
from pandas import DataFrame
from sklearn import tree
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import GridSearchCV, KFold
from scripts.churn_functions import modernize, simple_split, bake
import warnings

# do cv and fit with cost-complexity pruning
def tree_features(split,
                  scoring,
                  data_dir:str = "data/out/features.csv",
                  targetvar:str = 'n',
                  depth_range = np.arange(2, 8, 1),
                  verbose = 0):
    
    np.random.seed(1933)
    
    """
    Performs decision tree regression on 5-fold CV for file in data_dir.
    CV by cost-complexity on max_depth.
    Returns list of features.
    """
    data = pd.read_csv(data_dir)

    # Training data
    X, y = data.drop(columns = targetvar), data[targetvar]
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    # cv
    
    cv = KFold(n_splits=5, shuffle=True, random_state=1933)
    
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', tree.DecisionTreeRegressor())
        ])
    
    search = GridSearchCV(pipeline,
                      {'model__max_depth':depth_range},                      
                      cv = cv,
                      scoring = scoring,
                      verbose = verbose)
    
    search.fit(X_train, y_train)
    
    if verbose > 0:
        print(search.best_params_)
    
    # train
    cvd = Pipeline([
        ('scaler', StandardScaler()),
        ('model', tree.DecisionTreeRegressor(max_depth=search.best_params_['model__max_depth']))    
        ])
    
    model = cvd.fit(X_train, y_train)
    
    imp = X_train.columns[model.named_steps['model'].feature_importances_ > 0]
    
    return list(imp)