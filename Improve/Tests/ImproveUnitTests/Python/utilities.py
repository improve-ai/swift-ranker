# python 2
# JSON utilities
from flatten_json import flatten
import datetime
import json

def properties_to_features(prefix="", properties=None):
    
    # convert to flattened keys
    flattened = flatten(properties, '.')

    features = {}
    
    for key, value in flattened.viewitems():
        key = key.encode('utf-8')
        if isinstance(value, bool): # check bool first, because its an instanceof int
            features[prefix+key+'='+str(value).lower()] = 1.0 # one hot encode bools so that false isn't treated as missing data ## (11/2019, consider changing this to just 1.0 and 0.0, I think 0.0 isn't the same as missing for XGBoost)
        elif isinstance(value, (int, long, float)):
            features[prefix+key] = float(value)
        elif value is None: # json null, probably needs to be checked after the numerics to avoid 0s and falses being Noneish?
            features[prefix+key+'=null'] = 1.0
        elif isinstance(value,  datetime.datetime):
            features[prefix+key+'='+str(value)] = 1.0
            fill_date_features(features, prefix+key, value)
        else:
            features[u"%s%s=%s" % (prefix, key, value)] = 1.0

    return features
    
def fill_date_features(body, key, timestamp):
    
    if timestamp.tzinfo is None:
        timestamp = timestamp.replace(tzinfo=train_common.utc)
        
    midnight = timestamp.replace(hour=0, minute=0, second=0, microsecond=0)
        
    iso_year, iso_week, iso_week_day = timestamp.isocalendar()
    
    body[key+'.iso_week_day'] = float(iso_week_day)
    body[key+'.seconds_of_day'] = float((timestamp - midnight).total_seconds())
    
# returns a canonical json string if a complex object, or an "id" value if present, or a string encoding if its a basic type.
def variant_to_canonical_string(variant):
    if not isinstance(variant,(dict, list)):
        return str(variant)
        
    if isinstance(variant, dict) and "id" in variant:
        return str(variant["id"])
        
    return json.dumps(variant, separators=(',', ':'), sort_keys=True) # sort keys and ensure that the JSON has no extra padding so that all equivalent objects return the exact same string

