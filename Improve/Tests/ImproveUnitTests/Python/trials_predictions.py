"""
Calculates predictions for randomly generated trials using the model.
Creates 'trials.json' output which may be used for testing.

Args:
1) .xgb model path
2) model metadata .json
3) path to .py file where the FeatureEncoder class is defined

python3
"""

import sys
import json
import importlib
import xgboost as xgb
import pandas as pd
import random
import string
import os


def random_key():
    return ''.join(random.choices(string.ascii_letters + string.digits, k=7))

def random_trial():
    trial = {}
    for i in range(30):
        trial[random_key()] = random.random()
    return trial

trials = [random_trial() for i in range(10)]

metadata = json.load(open(sys.argv[2]))
lookupTable = metadata['table']
n_features = len(lookupTable[1])

encoder_folder, encoder_filename = os.path.split(sys.argv[3])
sys.path.append(os.path.abspath(encoder_folder))
FeatureEncoder = importlib.import_module(os.path.splitext(encoder_filename)[0]).FeatureEncoder
encoder = FeatureEncoder(lookupTable, metadata["model_seed"])
encoded_trials = map(lambda trial: encoder.encode_features(trial), trials)
df = pd.DataFrame(encoded_trials, columns=[i for i in range(n_features)])
testData = xgb.DMatrix(df)

modelPath = sys.argv[1]
model = xgb.Booster()
model.load_model(modelPath)
predictions = model.predict(testData).tolist()
print(predictions)

output = {"trials": trials, "predictions": predictions}
with open('trials.json', 'w') as outfile:
    json.dump(output, outfile, indent=2)

