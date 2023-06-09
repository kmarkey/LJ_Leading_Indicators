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

from thon.churn_functions import modernize, bake, simple_split

def run_lstm(split,
             num_epochs = 100,
             learning_rate = 0.01,
             hidden_size = 32,
             n_layers = 1, 
             feature_selection = None,
             data_dir:str = "data/out/features.csv",
             targetvar:str = 'n',
             verbose = 0):
    
    torch.manual_seed(1933)
    
    data = pd.read_csv(data_dir)
    
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
    
    class LSTM1(nn.Module):
        def __init__(self, input_size, hidden_size, num_layers, seq_length):
            super(LSTM1, self).__init__()
            self.num_layers = num_layers #number of layers
            self.input_size = input_size #input size
            self.hidden_size = hidden_size #hidden state
            self.seq_length = seq_length #sequence length

            self.lstm = nn.LSTM(input_size=input_size, hidden_size=hidden_size,
                              num_layers=num_layers, batch_first=True, dropout = 0) #lstm
            self.fc_1 =  nn.Linear(hidden_size, 16) #fully connected 1
            self.fc = nn.Linear(16, 1) #fully connected last layer

            self.relu = nn.ReLU()
    
        def forward(self,x):
            h_0 = Variable(torch.zeros(self.num_layers, x.size(0), self.hidden_size)) #hidden state
            c_0 = Variable(torch.zeros(self.num_layers, x.size(0), self.hidden_size)) #internal state
            # Propagate input through LSTM
            output, (hn, cn) = self.lstm(x, (h_0, c_0)) #lstm with input, hidden, and internal state
            hn = hn.view(-1, self.hidden_size) #reshaping the data for Dense layer next
            out = self.relu(hn)
            out = self.fc_1(out) #first Dense
            out = self.relu(out) #relu
            out = self.fc(out) #Final Output
            return out
    
    # set params
    num_layers = n_layers #number of stacked lstm layers
    
    lstm1 = LSTM1(input_size, hidden_size, num_layers, X_train_tensors.shape[1]) #our lstm class 
    
    criterion = torch.nn.MSELoss()    # mean-squared error for regression
    optimizer = torch.optim.Adam(lstm1.parameters(), lr=learning_rate) 

    # train loop
    for epoch in range(num_epochs):
    
        outputs = lstm1(X_train_tensors)

        optimizer.zero_grad()

        loss = criterion(outputs, y_train_tensors)

        loss.backward()

        optimizer.step()
        
        if epoch % (num_epochs//10) == 1:
            with torch.no_grad():
                pred = lstm1(X_test_tensors)
                val_loss = criterion(pred, y_test_tensors)
            
            if verbose > 1:
                print("Epoch: %d, train loss: %1.5f, test loss: %1.5f" % (epoch, loss.item(), val_loss.item()))
    
    if verbose > 0:
        print(epoch, loss.item(), val_loss.item())

    lstm1.eval()
    
    # modernize
    X_modern = modernize(X_train)
    X_modern_tensors = Variable(torch.Tensor(X_scaler.transform(X_modern))).unsqueeze(1)
    
    with torch.no_grad():
        train_pred = lstm1(X_train_tensors)#forward pass
        test_pred = lstm1(X_test_tensors)#forward pass
        pred = lstm1(X_modern_tensors)
    
    # convert back to real scale
    train_pred = train_pred.data.numpy() #numpy conversion
    train_pred = y_scaler.inverse_transform(train_pred)
    test_pred = test_pred.data.numpy() #numpy conversion
    test_pred = y_scaler.inverse_transform(test_pred)
    y_pred = y_scaler.inverse_transform(pred)

    out = bake(y_train.squeeze(), y_test.squeeze(), train_pred.squeeze(), test_pred.squeeze(), y_pred.squeeze())
    
    return out, lstm1
    
