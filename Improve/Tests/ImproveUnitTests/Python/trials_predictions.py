"""
Calculates a predictions for some trials using the model.
Creates 'trials.json' output which may be used for testing.

Args: model url

python3
"""

import sys
import json
from sklearn.feature_extraction import FeatureHasher
from os import path
import xgboost
import random
import string

def random_key():
    return ''.join(random.choices(string.ascii_letters + string.digits, k=7))

def random_trial():
    trial = {}
    for i in range(30):
        trial[random_key()] = random.random()
    return trial

trials = [random_trial() for i in range(10)]

hashedTrials = FeatureHasher(n_features=10000).transform(trials)
testData = xgboost.DMatrix(hashedTrials)

modelPath = sys.argv[1]
model = xgboost.Booster()
model.load_model(modelPath)
predictions = model.predict(testData).tolist()
print(predictions)

output = {"trials": trials, "predictions": predictions}
with open('trials.json', 'w') as outfile:
    json.dump(output, outfile, indent=2)

