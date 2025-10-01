from collections import defaultdict
import csv

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


def chunker(seq, size):
    return (seq[pos : pos + size] for pos in range(0, len(seq), size))


if __name__ == "__main__":
    examples = defaultdict(list)
    status = defaultdict(int)
    with open("dist/report.csv") as f:
        reader = csv.DictReader(f)
        for row in reader:
            row["Compile"] = float(row["compile_ns"]) / 1e6 / 1000
            row["Cold"] = float(row["cold_ns"]) / 1e6
            row["Warm"] = float(row["warm_ns"]) / 1e6
            examples[row["name"]].append(row)
            status[(row["implementation"], row['name'])] += int(row["exit_status"])

    for name, data in examples.items():
        data = pd.DataFrame(data)
        data = data.melt(
            id_vars=["implementation"], value_vars=("Compile", "Cold", "Warm")
        )

        # Make rows with non-zero exit status invalid
        for index, row in data.iterrows():
            if status[(row["implementation"], name)] != 0:
                data.at[index, "value"] = np.nan

        data.rename(columns={"variable": "Variable"}, inplace=True)
        plt.figure(figsize=(6, 8), dpi=96)
        fig, ax1 = plt.subplots()

        plot = sns.barplot(data, x="implementation", y="value", hue="Variable", ax=ax1)
        plot.set(xlabel=None)
        plot.tick_params(axis="x", rotation=30)
        plt.tight_layout()

        # Configure both y axes
        ax1.set_ylabel("Validation time (ms)")
        ax2 = ax1.twinx()
        ax2.set_ylim(ax1.get_ylim())
        ax2.set_ylim(ax2.get_ylim()[0] * 1000, ax2.get_ylim()[1] * 1000)
        ax2.set_ylabel("Compile time (ms)")

        plot.get_figure().savefig(
            f"dist/results/plots/schemas/{name}.png", dpi=96, bbox_inches="tight"
        )
        plt.clf()
