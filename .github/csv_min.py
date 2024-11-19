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
min_cold_impls = set()
for schema, impl in data[data["exit_status"] == 0].groupby("name")["cold_ns"].idxmin():
    min_cold_impls.add((schema, impl))
min_warm_impls = set()
for schema, impl in data[data["exit_status"] == 0].groupby("name")["warm_ns"].idxmin():
    min_warm_impls.add((schema, impl))
min_compile_impls = set()
for schema, impl in data[data["exit_status"] == 0].groupby("name")["compile_ns"].idxmin():
    min_compile_impls.add((schema, impl))

# Get the next fastest implementation
next_fastest_cold = (
    data[data["exit_status"] == 0].groupby("name").agg({"cold_ns": get_second})
)
next_fastest_warm = (
    data[data["exit_status"] == 0].groupby("name").agg({"warm_ns": get_second})
)
next_fastest_compile = (
    data[data["exit_status"] == 0].groupby("name").agg({"compile_ns": get_second})
)

# Label each implementation which was the fastest
new_index = data.index.to_list()
for i, (impl, schema) in enumerate(new_index):
    if (impl, schema) in min_cold_impls:
        suffix = ":white_check_mark:"
        fast_time = data.at[(impl, schema), "cold_ns"]
        next_time = next_fastest_cold.loc[schema]["cold_ns"]

        # If this implementation is 20% faster than the next, add a trophy
        if fast_time < next_time * 0.8:
            suffix += " :trophy:"

        data.at[(impl, schema), "cold_ns"] = f"{fast_time} {suffix}"

    if (impl, schema) in min_warm_impls:
        suffix = ":white_check_mark:"
        fast_time = data.at[(impl, schema), "warm_ns"]
        next_time = next_fastest_warm.loc[schema]["warm_ns"]

        # If this implementation is 20% faster than the next, add a trophy
        if fast_time < next_time * 0.8:
            suffix += " :trophy:"

        data.at[(impl, schema), "warm_ns"] = f"{fast_time} {suffix}"

    if (impl, schema) in min_compile_impls:
        suffix = ":white_check_mark:"
        fast_time = data.at[(impl, schema), "compile_ns"]
        next_time = next_fastest_compile.loc[schema]["compile_ns"]

        # If this implementation is 20% faster than the next, add a trophy
        if fast_time < next_time * 0.8:
            suffix += " :trophy:"

        data.at[(impl, schema), "compile_ns"] = f"{fast_time} {suffix}"

data.to_csv(sys.stdout)
