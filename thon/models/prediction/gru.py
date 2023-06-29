import numpy as np
import pandas as pd
import os
import re
import warnings
from sklearn.preprocessing import StandardScaler, MinMaxScaler
import torch #pytorch
import torch.nn as nn
from torch.autograd import Variable 

from thon.churn_functions import modernize, bake, simple_split

def run_gru(
    data,
    split,
             feature_selection = None,
             targetvar:str = 'n',
             num_epochs = 100,
             learning_rate = 0.01,
             criterion = torch.nn.MSELoss(),
             hidden_size = 32, 
             verbose = 0):
    
    torch.manual_seed(1933)
        
    if feature_selection is not None:
        X, y = data[list(feature_selection)], data[[targetvar]]
        input_size = len(feature_selection)
    else:
        X, y = data.drop(columns = targetvar), data[[targetvar]]
        input_size = len(X.columns)
        
    # fit scalers to all data regardlss of split
    X_scaler = MinMaxScaler().fit(X)
    y_scaler = MinMaxScaler().fit(y)
    
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    # format to tensors and reshape
    X_train_tensors = Variable(torch.Tensor(X_scaler.transform(X_train))).unsqueeze(1)
    X_test_tensors = Variable(torch.Tensor(X_scaler.transform(X_test))).unsqueeze(1)

    y_train_tensors = Variable(torch.Tensor(y_scaler.transform(y_train)))
    y_test_tensors = Variable(torch.Tensor(y_scaler.transform(y_test)))
    
    class GRUNet(nn.Module):
        def __init__(self, input_size, hidden_size, num_layers):
            super(GRUNet, self).__init__()
            self.hidden_size = hidden_size
            self.num_layers = num_layers
            self.gru = nn.GRU(input_size, hidden_size, num_layers, batch_first=True, dropout=0)
            self.fc = nn.Linear(hidden_size, 1)
            self.relu = nn.ReLU()

        def forward(self, x):
            h_0 = Variable(torch.zeros(self.num_layers, x.size(0), self.hidden_size)) #hidden state
            # Propagate input through LSTM
            output, hn = self.gru(x, h_0) #lstm with input, hidden, and internal state
            hn = hn.view(-1, self.hidden_size) #reshaping the data for Dense layer next
            out = self.relu(hn)
            out = self.fc(out) #first Dense
            return out
    
    # set params
    num_layers = n_layers #number of stacked lstm layers
    
    gru = GRUNet(input_size, hidden_size, num_layers)    
    
    optimizer = torch.optim.Adam(gru.parameters(), lr=learning_rate) 

    # train loop
    for epoch in range(num_epochs):
    
        outputs = gru(X_train_tensors)

        optimizer.zero_grad()

        loss = criterion(outputs, y_train_tensors)

        loss.backward()

        optimizer.step()
        
        if epoch % (num_epochs//10) == 1:
            with torch.no_grad():
                pred = gru(X_test_tensors)
                val_loss = criterion(pred, y_test_tensors)
            
            if verbose > 1:
                print("Epoch: %d, train loss: %1.5f, test loss: %1.5f" % (epoch, loss.item(), val_loss.item()))

    if verbose > 0:
        print(epoch, loss.item(), val_loss.item())
        
    gru.eval()
    
    # modernize
    X_modern = modernize(X_train)
    X_modern_tensors = Variable(torch.Tensor(X_scaler.transform(X_modern))).unsqueeze(1)
    
    with torch.no_grad():
        train_pred = gru(X_train_tensors)#forward pass
        test_pred = gru(X_test_tensors)#forward pass
        pred = gru(X_modern_tensors)
    
    # convert back to real scale
    train_pred = train_pred.data.numpy() #numpy conversion
    train_pred = y_scaler.inverse_transform(train_pred)
    test_pred = test_pred.data.numpy() #numpy conversion
    test_pred = y_scaler.inverse_transform(test_pred)
    y_pred = y_scaler.inverse_transform(pred)

    out = bake(y_train.squeeze(), y_test.squeeze(), train_pred.squeeze(), test_pred.squeeze(), y_pred.squeeze())
    
    return out
    
