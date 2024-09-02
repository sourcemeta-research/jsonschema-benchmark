from collections import defaultdict
import csv

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns



if __name__ == "__main__":
    examples = defaultdict(list)
    with open("dist/report.csv") as f:
        reader = csv.DictReader(f)
        for row in reader:
            row['milliseconds'] = float(row['nanoseconds']) / 1e6
            examples[row["name"]].append(row)

    for (name, data) in examples.items():
        data = pd.DataFrame(data)
        plt.figure(figsize=(4, 6), dpi=96)
        plot = sns.barplot(data, x="implementation", y="milliseconds", errorbar=None)
        plot.set(xlabel=None)
        plot.tick_params(axis='x', rotation=30)
        plt.tight_layout()
        plot.get_figure().savefig(f"dist/results/plots/{name}.png", dpi=96)
        plt.clf()

