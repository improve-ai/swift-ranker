# A script to make test cases for Objective-C implementation 
# of properties_to_features func.
from utilities import properties_to_features
import json

testInputs = [
 {'bar': ['baz', None, 1.0, 2]},
 {
 'browser': {'chrome': True, 'mozila': False},
 'os': {'android': False, 'ios': True},
 'sessionid': 1234567,
 'keywords': ['json', 'datetime', 'default', 'number']
 },
 {'true': 31, 'false': 20, 'null': None},
 {
 'large': 1.0, 'why': 3.0, 'being': 2.0,
 'meta': {'points': 7.839, 'gold': 5, 'silver': 46, 'bronze': 80}
 },
 {'feature': 'value'},
 {'tools': {'word': [3, 2, 3, 3], 'sentane': [3, 4, 4, False]}},
 {
 'wo': 0.97902098, 'fo': 1.0, 'ba': 0.11428571, 'al': 0.03125,
 'ar': 0.93853821, 'st': 0.95086705, 'sl': 0.33333333, 'dt': 0.00621118,
 'bg': 0.0, 'ot': 0.04347826, 'cz': 0.0, 'ps': 0.08333333
 },
 {
 'JSON Canonical Form': 631,
 'Table of contents': ['Definition', 'Example', 'Implementations', ['Validation'], 'Prior Art', 'Changelog', ['v1.0.0 (2017-10-17)', 'v1.0.1 (2018-07-01)', 'v1.0.2 (2019-04-14)']],
 'Definition': 2078,
 'Example': 129,
 'Implementations': 162,
 'Validation': 'True',
 'Prior Art': 'False',
 'Changelog': 'null'
 }
]

def makeTestCase(input):
  return {'in': input, 'out': properties_to_features(properties=input)}

testCases = list(map(makeTestCase, testInputs))
print(len(testCases))
with open('propertiesToFeatures.json', 'w') as outfile:
  json.dump(testCases, outfile, sort_keys=True)
