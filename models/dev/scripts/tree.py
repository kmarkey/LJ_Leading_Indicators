import os
import re
import numpy as np
import pandas as pd
import warnings
from pandas import DataFrame
from sklearn.tree import DecisionTreeRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import GridSearchCV, KFold

from scripts.churn_functions import modernize, simple_split, bake

# do cv and fit with cost-complexity pruning
class decision_tree():
    
    def __init__(self):
        pass
    
    def fit(self,
            data,
                 split,
                 scoring,
                 feature_selection = None,
                 targetvar:str = 'n'):
    
        """
        Runs decision tree regression by split with optional feature selection
        scoring used by GridSearchCV
        If feature_selection is True, performs selection on the fly with cross-validated cost-complexity pruning
        If feature_selection is a list of feature names, it uses all features in the list.
        targetvar is 'n' by default.
        """
        # rewrite attributes
        self.data = data
        self.split = split
        self.scoring = scoring
        self.feature_selection = feature_selection
        self.targetvar = targetvar
        
        # feature selection
        if feature_selection == True:

            X, y = data.drop(columns = self.targetvar), data[self.targetvar]

            pipeline = Pipeline([
                ('scaler', StandardScaler()),
                ('model', DecisionTreeRegressor())
                ])

            cv = KFold(n_splits=5, shuffle=True, random_state=1933)
            
            model = GridSearchCV(pipeline,
                                  {'model__max_depth':np.arange(2, 20, 1)}, # at least 2
                                  cv = cv,
                                  scoring = self.scoring,
                                  refit = True)
            
            def get_fnames(model):
                
                imp = model.best_estimator_.named_steps['model'].feature_importances_

                return list(self.__X_train__.columns[imp > 0])
            
        elif type(self.feature_selection) == list:
            
            X, y = data[list(self.feature_selection)], data[self.targetvar]

            model = Pipeline([
            ('scaler', StandardScaler()),
            ('model', DecisionTreeRegressor())
            ])
            
            def get_fnames(model):
                return list(getattr(model, "feature_names_in_"))
            
        # no feature selection
        else:
            
            X, y = data.drop(columns = self.targetvar), data[self.targetvar]

            model = Pipeline([
            ('scaler', StandardScaler()),
            ('model', DecisionTreeRegressor())
            ])
            
            def get_fnames(model):
                return list(getattr(model, "feature_names_in_"))
            
        np.random.seed(1933)

        X_train, X_test, y_train, y_test = simple_split(X, y, split)

        model = model.fit(X_train, y_train)

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
        
        # by feature_importance attribute
        if self.feature_selection == True:
            coef = self.model.best_estimator_['model'].feature_importances_
        else:
            coef = self.model['model'].feature_importances_
            
        impos = pd.DataFrame({'imp': coef,
              'name': self.__X_train__.columns}).sort_values('imp', ascending = False).nlargest(n, columns = 'imp')
        
        if names == True:
            
            return impos['name'].values
        else:
            return impos
    # save diagram
    #     tree.plot_tree(model[1])
    #     out_file = "thon/models/figs/tree.dot", feature_names = list(X_train))