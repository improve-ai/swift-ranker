"""
Creates trials to test Improve remote training.

Args:
1) Mode: sort, context
1) Number of trials to generate
2) (Optional, only for 'sort' mode) Number of keys in context to generate, defaults to 0.

Output for 'sort' mode: MultitypeSortTestTrainingData.json
{
    'trials': [...]
    'rewards': [...]
    'context': {...}
    'namespace': '...'
}

Output for 'context' mode: MultitypeContextTestTrainingData.json
[
    // str:
    {
        namespace: "...",
        variants: [...],
        bestVariantKey: "...",
        bestVariant: ...
    },
    // numb:
    ...
    // (all other types)
]

Task: https://trello.com/c/Vi9gEwZ8

python3
"""

import sys
import json
import random
import string
import os


def random_key(min_length=2, max_length=6):
    length = random.randint(min_length, max_length)
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def random_variant(type='rand', nested_weight_multiplier=1):
    nw = nested_weight_multiplier
    if type == 'rand':
        type = random.choices(
            ['str', 'numb', 'dict', 'array', 'bool', 'null', 'empty_str', 'empty_dict', 'empty_arr'],
            [100, 30, 20 * nw, 20 * nw, 9, 3, 2, 2, 2]
        )[0]

    if type == 'numb':
        return random.uniform(100, 1000000)
    elif type == 'str':
        return random_key()
    elif type == 'null':
        return None
    elif type == 'array':
        n = random.randint(2, 5)
        return [random_variant(nested_weight_multiplier=0.5) for i in range(n)]
    elif type == 'dict':
        n = random.randint(1, 4)
        return { random_key(): random_variant(nested_weight_multiplier=0.5) for i in range(n) }
    elif type == 'bool':
        return bool(random.getrandbits(1))
    elif type == 'empty_str':
        return ""
    elif type == 'empty_dict':
        return {}
    elif type == 'empty_arr':
        return []

def generate_sort_trials():
    trials_count = int(sys.argv[2])

    context_size = 0
    if len(sys.argv) > 3:
        context_size = int(sys.argv[3])

    sortedRewards = sorted([random.uniform(0, 100) for i in range(trials_count)], reverse=True)
    output = {
        'trials': [random_variant() for i in range(trials_count)],
        'rewards': sortedRewards,
        'context': { random_key(): random_variant() for i in range(context_size) },
        'namespace': "multitype_sort_test-{}".format(random_key(4,5))
    }

    print(output)
    with open('MultitypeSortTestTrainingData.json', 'w') as outfile:
        json.dump(output, outfile, indent=2)

def generate_context_trials():
    trials_count = int(sys.argv[2])
    output = []
    all_types = ['str', 'numb', 'dict', 'array', 'bool', 'null', 'empty_str', 'empty_dict', 'empty_arr']
    for type in all_types:
        variants = [random_variant() for i in range(trials_count - 1)]
        bestVariant = random_variant(type)
        variants.append(bestVariant)
        output.append({
            'variants': variants,
            'bestVariant': bestVariant,
            'bestVariantKey': random_key(),
            'namespace': 'multitype_context_test_{}-{}'.format(type, random_key(4,5))
        })

    print(output)
    with open('MultitypeContextTestTrainingData.json', 'w') as outfile:
        json.dump(output, outfile, indent=2)


mode = sys.argv[1]

if mode == 'sort':
    generate_sort_trials()
elif mode == 'context':
    generate_context_trials()
else:
    print("Unsupported mode:", mode)
