from collections import defaultdict
import csv
import sys

import pandas as pd


def get_second(lst):
    """
    Return the second smallest value in a list
    or zero if the list is not big enough
    """
    if len(lst) > 1:
        return sorted(lst)[1]
    else:
        return 0


# Average out runtime across runs
data = (
    pd.read_csv("dist/report.csv")
    .groupby(["implementation", "version", "name"])
    .mean()
    .astype("int")
)
data.reset_index(inplace=True)
data.set_index(["implementation", "name"], inplace=True)

# Get the fastest implementations
min_impls = set()
for schema, impl in data[data["exit_status"] == 0].groupby("name")["cold_ns"].idxmin():
    min_impls.add((schema, impl))

# Get the next fastest implementation
next_fastest = (
    data[data["exit_status"] == 0].groupby("name").agg({"cold_ns": get_second})
)

# Label each implementation which was the fastest
new_index = data.index.to_list()
for i, (impl, schema) in enumerate(new_index):
    if (impl, schema) in min_impls:
        new_name = impl + ":white_check_mark:"
        fast_time = data.at[(impl, schema), "cold_ns"]
        next_time = next_fastest.loc[schema]["cold_ns"]

        # If this implementation is 20% faster than the next, add a trophy
        if fast_time < next_time * 0.8:
            new_name += ":trophy:"

        new_index[i] = (new_name, impl)

# Apply the new names
data.index = pd.MultiIndex.from_tuples(new_index, names=["implementation", "schema"])

# Reset column order
data.reset_index(inplace=True)
data.set_index(["implementation", "version", "schema"], inplace=True)

data.to_csv(sys.stdout)
