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

# The cost of parsing and validating each instance once, cold and warm,
# and the entire cold start path: compile the schema, parse and validate
data["cold_parse_ns"] = data["cold_ns"] + data["parse_ns"]
data["warm_parse_ns"] = data["warm_ns"] + data["parse_ns"]
data["compile_cold_parse_ns"] = data["compile_ns"] + data["cold_ns"] + data["parse_ns"]

# The measures for which the fastest implementation is marked
MEASURES = ["cold_ns", "warm_ns", "compile_ns", "parse_ns", "cold_parse_ns", "warm_parse_ns", "compile_cold_parse_ns", "memory"]

succeeded = data[data["exit_status"] == 0]

# Get the fastest implementation for each measure and schema,
# along with the next fastest one
fastest = {}
next_fastest = {}
for measure in MEASURES:
    fastest[measure] = set(succeeded.groupby("name")[measure].idxmin())
    next_fastest[measure] = succeeded.groupby("name").agg({measure: get_second})

# Label each implementation which was the fastest
data = data.astype({measure: "object" for measure in MEASURES})
for impl, schema in data.index.to_list():
    for measure in MEASURES:
        if (impl, schema) not in fastest[measure]:
            continue

        suffix = ":white_check_mark:"
        fast_value = data.at[(impl, schema), measure]
        next_value = next_fastest[measure].loc[schema][measure]

        # If this implementation is 20% faster than the next, add a trophy
        if fast_value < next_value * 0.8:
            suffix += " :trophy:"

        data.at[(impl, schema), measure] = f"{fast_value} {suffix}"

columns = ["version", "cold_ns", "warm_ns", "compile_ns", "parse_ns", "cold_parse_ns", "warm_parse_ns", "compile_cold_parse_ns", "memory", "exit_status"]
data.reset_index()[["implementation", "name"] + columns].to_markdown(sys.stdout, index=False)
