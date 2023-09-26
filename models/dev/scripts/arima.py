import numpy as np
import pandas as pd
import os
import re
import warnings
from statsmodels.tsa.arima.model import ARIMA
from scripts.churn_functions import simple_split, bake, modernize
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from scripts.churn_functions import modernize, bake, simple_split

class arima():
    def __init__(self):
        pass
    
    def fit(self,
            data,
            split,
            targetvar:str = 'n',
            feature_selection = None,
            order = (12, 1, 0)):
    
        # rewrite attributes
        self.data = data
        self.split = split
        self.targetvar = targetvar
        self.order = order

        """
        Runs ARIMA by split without exogenous regressors.
        targetvar is 'n' by default.
        order is (12, 1, 0) by default
        """
            
        X, y = data.drop(columns = targetvar), data[targetvar]

        X_train, X_test, y_train, y_test = simple_split(X, y, split)

        if feature_selection == None:
            exog = None
        else:
            exog = X_train
            
        scaling = Pipeline([
            ('scaler', StandardScaler())
            ])
        
        scaled_X = scaling.fit_transform(X_train, y_train)
        
        model = ARIMA(endog = y_train, 
#                     exog = scaled_X,
                      order = order)
                      
        self.model = model.fit()
        
        self.__X_train__ = X_train
        self.__y_train__ = y_train
        self.__X_test__ = X_test
        self.__y_test__ = y_test
        
    def predict(self, ahead = 3):

        # Store the fitted values with the same time index as the training data
        train_pred = pd.Series(self.model.predict(), index= self.__X_train__.index)

        # test prediction
        test_pred = pd.Series(self.model.predict(start = self.__X_test__.index.min(),
                                                 end = self.__X_test__.index.max()), index = self.__X_test__.index)

        # X_modern = modernize(list(self.__X_train__.columns), ahead = ahead)
        
        pred = self.model.predict(start = self.__X_test__.index.max() + 1,
                                 end = self.__X_test__.index.max() + ahead)

        self.full = bake(self.__y_train__, self.__y_test__, train_pred, test_pred, pred)