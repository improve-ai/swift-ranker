"""
Creates a JSON files consisting of inputs and outputs of
FeatureHasher transform. This data may be used to test the
Objective-C implementation.

Arguments: json file containting an array of dictionaries:
{ n_features": ..., "alternate_sign": ..., "x": ...},
where "x" is an object to hash.

python3
"""

import sys
import json
from sklearn.feature_extraction import FeatureHasher
from os import path

input = sys.argv[1]
testCases = []
with open(input,'r') as file:
  inputArray = json.load(file)

  for opts in inputArray:
    hasher = FeatureHasher(n_features=opts["n_features"],
                           alternate_sign=opts["alternate_sign"])
    result = hasher.transform(opts["x"]).toarray().tolist()
    testCases.append({'input': opts, 'output': result})

inputDir = path.dirname(path.abspath(input))
output = path.join(inputDir, "output.json")
print(output)
with open(output, 'w') as outfile:
  json.dump(testCases, outfile)
  print("Output:", output)

