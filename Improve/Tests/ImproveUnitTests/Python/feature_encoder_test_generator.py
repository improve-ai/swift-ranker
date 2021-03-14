from feature_encoder import FeatureEncoder
import json

list = ["string", 0, 1, -1, 2.2, -2.2, True, False, None, [], {}]

dict = {
"string": "string",
"zero": 0,
"nested dict": {
"one": 1,
"nested dict": {
"minus one": -1,
}},
"nested array": [ 2.2, [ -2.2, { "true": True, "false": False}]],
"nulls": [[], {}]
}

tests = ["string", 0, 1, -1, 2.2, -2.2, True, False, None, [], {}, list, dict]

def test_encode_context(noise):
    result = []
    for item in tests:
        features = encoder.encode_context(item, noise)
        result.append(features)
    resultJsonString = json.dumps(result)
    print('noise=', noise)
    print(resultJsonString, '\n')

def test_encode_variant(noise):
    result = []
    for item in tests:
        features = encoder.encode_variant(item, noise)
        result.append(features)
    resultJsonString = json.dumps(result)
    print('noise=', noise)
    print(resultJsonString, '\n')

encoder = FeatureEncoder(3)

testsJsonString = json.dumps(tests)
print(testsJsonString, '\n')

test_encode_context(0.0)
test_encode_context(0.5)
test_encode_context(1.0)

test_encode_variant(0.0)
test_encode_variant(0.5)
test_encode_variant(1.0)
