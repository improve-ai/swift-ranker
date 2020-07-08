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
    length = random.randint(2, 5)
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def random_variant():
    simple = random.random() < 0.8
    if simple:
        if random.random() < 0.9:
            type = random.choice(['numb', 'str'])
        else:
            type = 'null'
    else:
        type = random.choice(['array', 'dict'])

    if type == 'numb':
        return random.uniform(100, 1000000)
    elif type == 'str':
        return random_key()
    elif type == 'null':
        return None
    elif type == 'array':
        n = random.randint(2, 5)
        return [random_variant() for i in range(n)]
    elif type == 'dict':
        n = random.randint(1, 4)
        return dict([(random_key(), random_variant()) for i in range(n)])

trials = [random_variant() for i in range(40)]
context = {}
namespace = "test"

metadata = json.load(open(sys.argv[2]))
lookupTable = metadata['table']
n_features = len(lookupTable[1])

encoder_folder, encoder_filename = os.path.split(sys.argv[3])
sys.path.append(os.path.abspath(encoder_folder))
FeatureEncoder = importlib.import_module(os.path.splitext(encoder_filename)[0]).FeatureEncoder
encoder = FeatureEncoder(lookupTable, metadata["model_seed"])
encoded_context = encoder.encode_features({"context": {namespace: context}})
encoded_trials = map(lambda trial: encoder.encode_features({"variant": {namespace: trial}}, encoded_context), trials)
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

