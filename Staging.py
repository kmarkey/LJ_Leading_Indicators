# I use elastic net to select vars as it will adress multicollinearity and actually get rid of some features

import pandas as pd

# evaluate an elastic net model on the dataset
from numpy import mean
from numpy import std
from numpy import absolute
from pandas import read_csv
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import RepeatedKFold
from sklearn.linear_model import ElasticNet


# define model
model = ElasticNet(alpha=1.0, l1_ratio=0.5)

data = read_csv("data/complete.csv")
data = data.values

#separate x and y
X, y = data[:, 1:-1], data[:, 1]
# define model
model = ElasticNet(alpha = 1.0, l1_ratio = 0.5)
# define model evaluation method
cv = RepeatedKFold(n_splits = 10, n_repeats = 3, random_state = 1)
# evaluate model
scores = cross_val_score(model, X, y, scoring = 'neg_mean_absolute_error', cv = cv, n_jobs = -1)
# force scores to be positive
scores = absolute(scores)
print('Mean MAE: %.3f (%.3f)' % (mean(scores), std(scores)))
