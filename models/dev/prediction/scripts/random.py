import numpy as np
import pandas as pd
import os
import re
import warnings
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GridSearchCV, KFold
from sklearn.inspection import permutation_importance
from sklearn.pipeline import Pipeline

from scripts.churn_functions import modernize, bake, simple_split


class random_forest():
    def __init__(self):
        pass
    
    def fit(self,
            data,
                 split,
                 scoring,
                 feature_selection = None,
                 targetvar:str = 'n'):
    
        # rewrite attributes
        self.data = data
        self.split = split
        self.scoring = scoring
        self.feature_selection = feature_selection
        self.targetvar = targetvar
        
        # empty model
        model = Pipeline([
            ('scaler', StandardScaler()),
            ('model', RandomForestRegressor(n_estimators=100, random_state = 1966))
            ])
        
        cv = KFold(n_splits=5, shuffle=True, random_state=1933)
        
        model = GridSearchCV(model,
                              {'model__max_depth':np.arange(2, 10, 1),
                              'model__min_samples_leaf': [1, 2, 4, 6, 8]}, # at least 2
                              cv = cv,
                              scoring = self.scoring,
                              refit = True)

        # feature selection
        def get_xy():
            
            if self.feature_selection == True:

                X, y = data.drop(columns = self.targetvar), data[self.targetvar]

            # manual selection
            elif type(self.feature_selection) == list:

                X, y = data[list(self.feature_selection)], data[self.targetvar]
                
            # no feature selection
            else:

                X, y = data.drop(columns = self.targetvar), data[self.targetvar]
                                
            return X, y
                
        X, y = get_xy()
        
        # split data
        X_train, X_test, y_train, y_test = simple_split(X, y, self.split)
        
        # fit the model
        model = model.fit(X_train, y_train)
        
        # feature selection step
        if self.feature_selection == True:
            
            # extract feature importance on test set
            imps = permutation_importance(model, 
                                              X_test, 
                                              y_test, 
                                              n_repeats=10, 
                                              random_state=1933, 
                                              n_jobs=-1)
            
            self.feature_selection = list(X_test.columns[imps.importances_mean > np.mean(imps.importances_mean)])
            
#             # save df of importances
#             self.importances = pd.DataFrame({'imp':imps.importances_mean, # scaled, oops
#                   'name': X_train.columns}).sort_values('imp', ascending = False)

            # fit model again
            X, y = get_xy()
            
            X_train, X_test, y_train, y_test = simple_split(X, y, self.split)
        
            model.fit(X_train, y_train)
        
        # write hidden splits
        self.__X_train__ = X_train
        self.__y_train__ = y_train
        self.__X_test__ = X_test
        self.__y_test__ = y_test
        
        # save fitted model and fnames
        self.model = model
        self.fnames = model.feature_names_in_
                
    def predict(self):

        # Store the fitted values with the same time index as the training data
        train_pred = pd.Series(self.model.predict(self.__X_train__), index= self.__X_train__.index)

        # test prediction
        test_pred = pd.Series(self.model.predict(self.__X_test__), index = self.__X_test__.index)

        X_modern = modernize(list(self.__X_train__.columns))

        pred = self.model.predict(X_modern)

        self.full = bake(self.__y_train__, self.__y_test__, train_pred, test_pred, pred)
        
    def get_importances(self, n = None, names = False):
        
        if n is None:
            # default is all features
            n = self.__X_train__.shape[1]
        
        coef = self.model.best_estimator_['model'].feature_importances_
            
        impos = pd.DataFrame({'imp': coef,
              'name': self.__X_train__.columns}).sort_values('imp', ascending = False).nlargest(n, columns = 'imp')
        
        if names == True:
            
            return impos['name'].values
        else:
            return impos