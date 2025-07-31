import argparse

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="+")
    args = parser.parse_args()

    # Read the data
    data = pd.concat(pd.read_csv(f) for f in args.input)

    # Pick the schemas with the most benefit
    overall = data[(data["Run type"] == "Overall") & (data["Schema"] != "Overall")]
    max_schemas = overall.loc[overall.groupby(["Optimization"])["% speedup"].idxmax()][
        "Schema"
    ].tolist() + ["Overall"]
    # max_schemas = ["cql2", "helm-chart-lock", "krakend", "cmake-presets", "Overall"]
    data = data[data["Schema"].isin(max_schemas)]

    data["% speedup"] = data["% speedup"] * 100
    data.set_index(["Optimization", "Schema", "Run type"], inplace=True)
    sns.set_context(rc={"patch.linewidth": 1.0})

    sns.set(font_scale=2, style="whitegrid")
    plot = sns.catplot(
        data,
        x="Schema",
        col="Optimization",
        col_wrap=2,
        hue="Run type",
        y="% speedup",
        kind="bar",
        palette=["lightsteelblue", "orangered", "khaki"],
        aspect=4,
        legend_out=False,
    )
    plot.axes[0].set_ylim(0, 100)
    plot.set_titles("{col_name}")
    plot.savefig("dist/results/opt.png")
    plot.savefig("dist/results/opt.svg", dpi=96, bbox_inches="tight")
