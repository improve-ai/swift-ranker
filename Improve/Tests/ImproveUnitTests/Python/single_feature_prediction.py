"""
Itearatively sets one feature to 1 and all others to 0 and calculate predictions for such input arrays. The output is json array of predictions.
Args: model url, output url

python3
"""

import sys
from sklearn.feature_extraction import FeatureHasher
import xgboost
import json
import numpy as np

modelPath = sys.argv[1]
model = xgboost.Booster()
model.load_model(modelPath)

featuresCount = 10000
features = np.zeros(featuresCount)
predictions = []
for i in range(featuresCount):
  features[i] = 1.0
  prediction = model.predict(xgboost.DMatrix([features]))[0]
  predictions.append(prediction)
  features[i] = 0.0

# Convert to float to prevent json error
outputDict = { str(i) : float(predictions[i]) for i in range(0, len(predictions) ) }

outputJSONPath = sys.argv[2]
with open(outputJSONPath, 'w') as outputJSON:
  json.dump(outputDict, outputJSON)

