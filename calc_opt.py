import argparse
import sys

import pandas as pd


def read_report(filename):
    # Read a file and calculate average runtimes
    return (
        pd.read_csv(filename)
        .query("implementation == 'blaze'")
        .drop(["implementation", "version"], axis=1)
        .groupby(["name"])
        .mean()
        .astype("int")
    )


if __name__ == "__main__":
    # The two arguments are
    # - base: a run with all optimizations enabled
    # - no_opt: a run with some optimization(s) disabled
    parser = argparse.ArgumentParser()
    parser.add_argument("base")
    parser.add_argument("no_opt")
    parser.add_argument("optimization")
    args = parser.parse_args()

    # Read both reports
    base = read_report(args.base)
    base["optimized"] = 1
    no_opt = read_report(args.no_opt)
    no_opt["optimized"] = 0

    # Join the two reports based on schema
    diff = base.join(no_opt, on=["name"], lsuffix="_base", rsuffix="_no_opt")

    # Calculate total runtime
    diff["total_ns_base"] = diff["cold_ns_base"] + diff["warm_ns_base"]
    diff["total_ns_no_opt"] = diff["cold_ns_no_opt"] + diff["warm_ns_no_opt"]

    # Get the overall difference
    diff_sum = diff.sum()
    average = {
        "Schema": "Overall",
        "Cold": (diff_sum["cold_ns_no_opt"] - diff_sum["cold_ns_base"])
        / diff_sum["cold_ns_no_opt"],
        "Warm": (diff_sum["warm_ns_no_opt"] - diff_sum["warm_ns_base"])
        / diff_sum["warm_ns_no_opt"],
        "Overall": (diff_sum["total_ns_no_opt"] - diff_sum["total_ns_base"])
        / diff_sum["total_ns_no_opt"],
    }

    # Get the percentage difference for all three measurements
    diff["Cold"] = (diff["cold_ns_no_opt"] - diff["cold_ns_base"]) / diff[
        "cold_ns_no_opt"
    ]
    diff["Warm"] = (diff["warm_ns_no_opt"] - diff["warm_ns_base"]) / diff[
        "warm_ns_no_opt"
    ]
    diff["Overall"] = (diff["total_ns_no_opt"] - diff["total_ns_base"]) / diff[
        "total_ns_no_opt"
    ]

    # Sort by total difference
    diff.sort_values(by="Overall", inplace=True, ascending=False)

    # Keep only the relevant rows
    diff = diff[["Cold", "Warm", "Overall"]]

    # Add another row with the average
    diff = pd.concat([diff, pd.DataFrame.from_dict([average]).set_index("Schema")])

    # Properly name the schema column
    diff.index.set_names(["Schema"], inplace=True)

    # Reformat and output a CSV summary
    diff = diff.reset_index().melt(
        id_vars=["Schema"],
        value_vars=["Cold", "Warm", "Overall"],
        var_name="Run type",
        value_name="% speedup",
    )
    diff["Optimization"] = args.optimization
    diff.set_index("Schema", inplace=True)
    print(diff.to_csv())
