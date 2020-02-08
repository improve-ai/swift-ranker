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

trial = {
  "648:theme.id=Blurred Plants": 1,
  "648:theme.secondaryColor=c8dfd0": 1,
  "648:day": 0,
  "648:message.__sample": 0.02347148132950349,
  "648:language=English": 1,
  "648:theme.buttonTextColor=ffffff": 1,
  "648:page": 8,
  "648:version_name=6.1": 1,
  "648:device_model=iPhone11,8": 1,
  "648:device_manufacturer=Apple": 1,
  "648:country=United States": 1,
  "648:theme.primaryColor=ffffff": 1,
  "648:share_ratio": 0,
  "648:carrier=Verizon": 1,
  "648:os_version=13.3": 1,
  "648:message.text=Let it come. Let it be. Let it go.": 1,
  "648:theme.__sample": 0.014947494560247233,
  "648:theme.buttonBorderColor=c8dfd0": 1,
  "648:os_name=ios": 1,
  "648:theme.file=blurred_plants.png": 1
}
hashedTrial = FeatureHasher(n_features=10000).transform([trial])
testData = xgboost.DMatrix(hashedTrial)

modelPath = sys.argv[1]
model = xgboost.Booster()
model.load_model(modelPath)
prediction = model.predict(testData)
print(prediction)
