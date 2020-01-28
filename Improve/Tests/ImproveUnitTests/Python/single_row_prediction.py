"""
Calculates a prediction for the single row using the model.
Args: model url

python3
"""

import sys
import json
from sklearn.feature_extraction import FeatureHasher
from os import path
import xgboost

trial = {"buttonBorderColor":"efe4bc"}
hashedTrial = FeatureHasher(n_features=10000).transform([trial])
print(hashedTrial)
testData = xgboost.DMatrix(hashedTrial)

modelPath = sys.argv[1]
model = xgboost.Booster()
model.load_model(modelPath)
prediction = model.predict(testData)
print(prediction)
