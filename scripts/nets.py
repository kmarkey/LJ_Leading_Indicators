import torch
import torch.nn as nn
from torch.autograd import Variable 

class GRUNET(nn.Module):
    def __init__(self, input_size, hidden_size, num_layers):
        super(GRUNET, self).__init__()
        self.hidden_size = hidden_size
        self.num_layers = num_layers
        self.gru = nn.GRU(input_size, hidden_size, num_layers, batch_first=True, dropout=0.0)
        self.fc = nn.Linear(hidden_size, 1)
        self.relu = nn.ReLU()

    def forward(self, x):
        h_0 = Variable(torch.zeros(self.num_layers, x.size(0), self.hidden_size)) #hidden state
        # Propagate input through gru
        output, hn = self.gru(x, h_0) #lstm with input, hidden, and internal state
        hn = hn.view(-1, self.hidden_size) #reshaping the data for Dense layer next
        out = self.relu(hn)
        out = self.fc(out) #first Dense
        return out
    
class LSTMNET(nn.Module):
    def __init__(self, input_size, hidden_size, num_layers):
        super(LSTMNET, self).__init__()
        self.num_layers = num_layers #number of layers
        self.input_size = input_size #input size
        self.hidden_size = hidden_size #hidden state

        self.lstm1 = nn.LSTM(input_size=input_size, hidden_size=hidden_size,
                          num_layers=1, batch_first=True, dropout = 0) #lstm

        self.fc_1 =  nn.Linear(hidden_size, 16) #fully connected 1
        self.fc = nn.Linear(16, 1) #fully connected last layer

        self.relu = nn.Tanh()

    def forward(self,x):
        h_0 = Variable(torch.zeros(self.num_layers, x.size(0), self.hidden_size)) #hidden state
        c_0 = Variable(torch.zeros(self.num_layers, x.size(0), self.hidden_size)) #internal state

        # Propagate input through LSTM
        output, (hn, cn) = self.lstm1(x, (h_0, c_0)) #lstm with input, hidden, and internal state
        hn = hn.view(-1, self.hidden_size) #reshaping the data for Dense layer next
        x = self.relu(hn)
        x = self.fc_1(x) #first Dense
        x = self.relu(x) #relu
        out = self.fc(x) #Final Output
        return out