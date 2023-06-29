import numpy as np
import pandas as pd
import sklearn
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from statsmodels.tsa.arima.model import ARIMA
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.pipeline import Pipeline
import torch #pytorch
import torch.nn as nn
from torch.autograd import Variable 

from thon.churn_functions import modernize, bake, simple_split

def linear_regression(
    data,
    split,
                 feature_selection = None,
                 targetvar:str = 'n'):
    """
    Runs linear regression with optional feature selection on file in data_dir
    """
    
    if feature_selection is not None:
        X, y = data[list(feature_selection)], data[targetvar]
    else:
        X, y = data.drop(columns = targetvar), data[targetvar]
        
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    model = Pipeline([('scaler', StandardScaler()),
                      ('model', LinearRegression())])

    # Train the model
    model.fit(X_train, y_train)
    
    # Store the fitted values as a time series with the same time index as
    # the training data
    train_pred = pd.Series(model.predict(X_train), index = X_train.index)
    
    test_pred = pd.Series(model.predict(X_test), index = X_test.index)
    
    X_modern = modernize(list(X_train.columns))
    
    pred = model.predict(X_modern)
    
    out = bake(y_train, y_test, train_pred, test_pred, pred)
    
    return out

def decision_tree(data,
                  split,
                  feature_selection = None,
                  targetvar:str = 'n'):
    
    np.random.seed(1933)
    
    """
    Creates a decision tree with optimized cost-complexity pruning for file in data_dir.
    Saves and returns complete df
    """

    if feature_selection is not None:
        X, y = data[list(feature_selection)], data[targetvar]
    else:
        X, y = data.drop(columns = targetvar), data[targetvar]
        
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    # cv
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', DecisionTreeRegressor(max_depth = len(X_train.columns)))
        ])
    
    pipeline.fit(X_train, y_train)
    
    pred_train = pd.Series(pipeline.predict(X_train), index=X_train.index)
    pred_test = pd.Series(pipeline.predict(X_test), index=X_test.index)
    
    pred = pipeline.predict(modernize(X_train))
    
    out = bake(y_train, y_test, pred_train, pred_test, pred)
    
    # save diagram
    #     tree.plot_tree(model[1])
    #     out_file = "thon/models/figs/tree.dot", feature_names = list(X_train))
        
    return out

def random_forest(data,
                  split,
                  feature_selection = None,
                  targetvar:str = 'n'):
        
    if feature_selection is not None:
        X, y = data[list(feature_selection)], data[targetvar]
    else:
        X, y = data.drop(columns = targetvar), data[targetvar]
        
    X_train, X_test, y_train, y_test = simple_split(X, y, split)
    
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('model', RandomForestRegressor(random_state = 25,
                                        bootstrap=False,
                                        max_features="sqrt",
                                        n_estimators=250,
                                        max_depth = 3)) # was cv
    ])
    
    pipeline.fit(X_train, y_train)
    
    pred_train = pd.Series(pipeline.predict(X_train), index=X_train.index)
    pred_test = pd.Series(pipeline.predict(X_test), index=X_test.index)
    
    pred = pipeline.predict(modernize(X_train))
    
    out = bake(y_train, y_test, pred_train, pred_test, pred)
    
    return out

def run_arima(data,
              split,
              targetvar:str = 'n',
              verbose = 0):
    
    X, y = data.drop(columns = targetvar), data[targetvar]

    X_train, X_test, y_train, y_test = simple_split(X, y, split)
        
    X_train, X_test = y_train.values, y_test.values
    
    # start with reversed history
    history = [x for x in X_train[::-1]]

    predictions = list()

    # walk-forward prediction
    train_pred = []
    for t in range(len(X_train)):
        model = ARIMA(history, order=(12,1,0))
        model_fit = model.fit()
        output = model_fit.forecast()
        yhat = output[0]
        obs = y_train[t]
        history.append(obs)
        train_pred.append(yhat)
        if verbose == 2:
            print('predicted=%f, expected=%f' % (yhat, obs))
        
    # test prediction
    test_pred = []
    for t in range(len(X_test)):
        model = ARIMA(history, order=(12,1,0))
        model_fit = model.fit()
        output = model_fit.forecast()
        yhat = output[0]
        predictions.append(yhat)
        obs = X_test[t]
        history.append(obs)
        test_pred.append(yhat)
        if verbose == 2:
            print('predicted=%f, expected=%f' % (yhat, obs))
        
    # pred
    pred = []
    for t in range(3):
        model = ARIMA(history, order=(12,1,0))
        model_fit = model.fit()
        output = model_fit.forecast()
        yhat = output[0]
        predictions.append(yhat)
        history.append(yhat) # predict with yhat
        pred.append(yhat)
        if verbose == 2:
            print('predicted=%f, %', (yhat))
            
    out = bake(y_train, y_test, train_pred, test_pred, pred)
    
    return out

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
    
    gru = GRUNet(input_size, hidden_size, 1)    
    
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
    
def run_lstm(
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
    
    lstm1 = LSTM1(input_size, hidden_size, 1, X_train_tensors.shape[1]) #our lstm class 

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
    
    return out