import numpy as np
import pandas as pd
import os
import re
import warnings
from sklearn.linear_model import LinearRegression, Lasso
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import GridSearchCV, KFold
from scripts.churn_functions import modernize, bake, simple_split

class linear_regression():
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
    
        """
        Runs linear regression by split with optional feature selection.
        Feature importance roughly determined by coefficient
        scoring used by GridSearchCV
        If feature_selection is True, performs selection on the fly with cross-validated Lasso regression.
        If feature_selection is a list of feature names, it uses all features in the list.
        targetvar is 'n' by default.
        """

        # feature selection
        if self.feature_selection == True:

            X, y = data.drop(columns = self.targetvar), data[self.targetvar]

            model = Pipeline([
                ('scaler', StandardScaler()),
                ('model', Lasso())
                ])

            cv = KFold(n_splits=5, shuffle=True, random_state=1933)
            
            model = GridSearchCV(model,
                                  {'model__alpha':np.arange(2, 20, 1)}, # at least 2
                                  cv = cv,
                                  scoring = self.scoring,
                                  refit = True)
            
            def get_fnames(model):
                coef = model.best_estimator_['model'].coef_
                return list(self.__X_train__.columns[coef != 0])
            
        # manual selection
        elif type(self.feature_selection) == list:
            
            X, y = data[list(self.feature_selection)], data[self.targetvar]

            model = Pipeline([
            ('scaler', StandardScaler()),
            ('model', LinearRegression())
            ])
            
            def get_fnames(model):
                return list(getattr(model, "feature_names_in_"))
                
        # no feature selection
        else:
            
            X, y = data.drop(columns = self.targetvar), data[self.targetvar]

            model = Pipeline([
            ('scaler', StandardScaler()),
            ('model', LinearRegression())
            ])
            
            def get_fnames(model):
                return list(getattr(model, "feature_names_in_"))
                
        # split data
        X_train, X_test, y_train, y_test = simple_split(X, y, self.split)

        # Train the model
        model.fit(X_train, y_train)

        # write hidden splits
        self.__X_train__ = X_train
        self.__y_train__ = y_train
        self.__X_test__ = X_test
        self.__y_test__ = y_test
        
        # save fitted model and fnames
        self.model = model
        self.fnames = get_fnames(model)
        
    def predict(self, ahead = 3):

        # Store the fitted values with the same time index as the training data
        train_pred = pd.Series(self.model.predict(self.__X_train__), index= self.__X_train__.index)

        # test prediction
        test_pred = pd.Series(self.model.predict(self.__X_test__), index = self.__X_test__.index)

        X_modern = modernize(list(self.__X_train__.columns), ahead = ahead)

        pred = self.model.predict(X_modern)

        self.full = bake(self.__y_train__, self.__y_test__, train_pred, test_pred, pred)
        
    def get_importances(self, n = None, names = False):
        
        if n is None:
            # default is all features
            n = self.__X_train__.shape[1]
        
        # by coefficient value
        if self.feature_selection == True:
            coef = self.model.best_estimator_['model'].coef_
        else:
            coef = self.model['model'].coef_
            
        impos = pd.DataFrame({'imp': coef,
              'name': self.__X_train__.columns}).sort_values('imp', ascending = False).nlargest(n, columns = 'imp')
        
        if names == True:
            
            return impos['name'].values
        else:
            return impos

                
    