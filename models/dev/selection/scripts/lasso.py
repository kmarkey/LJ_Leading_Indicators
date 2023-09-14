import numpy as np
import pandas as pd
import os
import re
import warnings
from sklearn.linear_model import Lasso
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.model_selection import GridSearchCV, KFold
from scripts.churn_functions import simple_split

def lasso_features(split,
               scoring,
               data_dir:str = "data/out/features.csv",
               targetvar:str = 'n',
               alpha_range = np.arange(2, 20, 1),
               verbose = 0):
    """
    Performs L1 regularization on 5-fold CV for file in data_dir.
    Returns list of features.
    """
    data = pd.read_csv(data_dir)
    
    # Training data
    X, y = data.drop(columns = targetvar), data[targetvar]
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('model', Lasso())
    ])

    cv = KFold(n_splits=5, shuffle=True, random_state=1933)
    
    search = GridSearchCV(pipeline,
                      {'model__alpha':alpha_range}, # at least 2
                      cv = cv,
                      scoring = scoring,
                      verbose = verbose)

    search.fit(X_train, y_train)

    coef = search.best_estimator_[1].coef_
    
    # get nonzero coefs
    out = X_train.iloc[:, coef != 0]
    
    return list(out.columns)