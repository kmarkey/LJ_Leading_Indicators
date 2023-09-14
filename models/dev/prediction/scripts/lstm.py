import numpy as np
import pandas as pd
import os
import pickle
import re
import warnings
from sklearn.preprocessing import StandardScaler, MinMaxScaler
import torch #pytorch
import torch.nn as nn
from torch.autograd import Variable 

from scripts.churn_functions import modernize, bake, simple_split

class lstm():
    def __init__(self):
        pass
        
    def fit(self,
            data,
            split,
             feature_selection = None,
             targetvar:str = 'n',
             num_epochs = 100,
             learning_rate = 0.01,
             scoring = torch.nn.MSELoss(),
             hidden_size = 16, 
             verbose = 0):

        """
        Trains a bilayer lstm network with optional feature selection.
        Scoring should be a loss function
        Feature importance is calculated by integrated gradients
        targetvar is 'n' by default.
        """
            
        self.data = data
        self.split = split
        self.scoring = scoring
        self.feature_selection = feature_selection
        self.targetvar = targetvar
        
        torch.manual_seed(1933)
        self.torch_seed = 1933
        
        if feature_selection is not None:
            X, y = data[list(feature_selection)], data[[targetvar]]
            
            input_size = len(feature_selection)
            
        else:
            
            X, y = data.drop(columns = targetvar), data[[targetvar]]
            input_size = len(X.columns)
            
        X_train, X_test, y_train, y_test = simple_split(X, y, split)
        
        # train scalers
        # seems to work better with minmax
        #StandardScaler()
        self.scale_X = MinMaxScaler().fit(X_train)  
        self.scale_y = MinMaxScaler().fit(y_train)   
        
        # format to tensors and reshape
        X_train_tensors = Variable(torch.Tensor(self.scale_X.transform(X_train))).unsqueeze(1)
        X_test_tensors = Variable(torch.Tensor(self.scale_X.transform(X_test))).unsqueeze(1)

        y_train_tensors = Variable(torch.Tensor(self.scale_y.transform(y_train)))
        y_test_tensors = Variable(torch.Tensor(self.scale_y.transform(y_test)))

        # put in script to call
        from scripts.nets import LSTMNET

        # set params
        num_layers = 1 #number of stacked lstm layers

        model = LSTMNET(input_size, hidden_size, num_layers)    
        
        optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate) 

        # training
        for epoch in range(num_epochs):

            outputs = model(X_train_tensors)

            optimizer.zero_grad()

            loss = scoring(outputs, y_train_tensors)

            loss.backward()

            optimizer.step()

            if epoch % (num_epochs // 10) == 0:
                with torch.no_grad():
                    pred = model(X_test_tensors)
                    val_loss = scoring(pred, y_test_tensors)

                if verbose > 1:
                    print("Epoch: %d, train loss: %1.5f, test loss: %1.5f" % (epoch, loss.item(), val_loss.item()))

        # write attributes
        self.__X_train__ = X_train
        self.__y_train__ = y_train
        self.__X_test__ = X_test
        self.__y_test__ = y_test
        self.__X_train_tensors__ = X_train_tensors
        self.__y_train_tensors__ = y_train_tensors
        self.__X_test_tensors__ = X_test_tensors
        self.__y_test_tensors__ = y_test_tensors
        
        # save fitted model and fnames
        self.model = model
        
    def predict(self, ahead = 3):

        self.model.eval()
        
        # modernize
        X_modern = modernize(self.__X_train__.columns)
        X_modern_tensors = Variable(torch.Tensor(self.scale_X.transform(X_modern))).unsqueeze(1)

        # forward pass with scaled tensors
        with torch.no_grad():
            train_pred = self.model(self.__X_train_tensors__)
            test_pred = self.model(self.__X_test_tensors__)
            pred = self.model(X_modern_tensors)
        
        self.__X_modern__ = X_modern
        self.__X_modern_tensors__ = X_modern_tensors
        
        #convert back to normal scale
        train_pred = self.scale_y.inverse_transform(train_pred)
        test_pred = self.scale_y.inverse_transform(test_pred)
        pred = self.scale_y.inverse_transform(pred)

        self.full = bake(self.__y_train__.squeeze(), self.__y_test__.squeeze(), train_pred.squeeze(), test_pred.squeeze(), pred.squeeze())
    
    def get_importances(self, n = None, names = False):

        ig = IntegratedGradients(self.model)
        
        attr, delta = ig.attribute(self.__X_test_tensors__, target = 0, return_convergence_delta = True)
        
        self.delta = delta
        
        if n is None:
            # default is all features
            n = self.__X_test_tensors__.shape[2]
        
        attr = attr.detach().numpy()

        impos = pd.DataFrame({'imp': np.mean(np.abs(attr), axis=0).squeeze(),
                      'name': self.__X_test__.columns}).sort_values('imp', ascending = False).nlargest(n, columns = 'imp')

        if names == True:
            
            return impos['name'].values
        else:
            return impos
    
