import mmh3
import numpy as np

import glob
import json


# This replicates the logic of PropertyHashJSON
def hash(string):
    hash_val = np.zeros(32)
    if len(string) <= 31:
        hash_val[1:len(string) + 1] = np.array([ord(c) for c in string])
    else:
        hash_val[0] = (len(string) + ord(string[0]) + ord(string[-1])) % 256
        # hash_val[1:32] = np.array([ord(c) for c in string[:31]])
    return tuple(hash_val)


def get_keys(obj):
    if isinstance(obj, dict):
        # Produce the keys for this object
        yield set(obj.keys())

        # Recursively search objects
        for key, value in obj.items():
            yield from get_keys(value)
    elif isinstance(obj, list):
        # Recursively search arrays
        for value in obj:
            yield from get_keys(value)

if __name__ == "__main__":
    rates = []
    # Loop over instances for all schema
    for instances in sorted(glob.glob('schemas/*/instances.jsonl')):
        total = 0
        collisions = 0
        with open(instances) as f:
            for line in f:
                # Loop overall keys in objects
                obj = json.loads(line)
                for keys in get_keys(obj):
                    # Skip cases where collisions are impossible
                    if len(keys) <= 1:
                        continue

                    # Check for collisions
                    total += 1
                    hashes = {hash(key) for key in keys}
                    if len(hashes) < len(keys):
                        collisions += 1

            rates.append(collisions / total)
        print(f'{instances} {collisions}/{total}={collisions/total * 100:.2f}%')
    print(f'\n    Total {sum(rates) / len(rates) * 100:.2f}%')
