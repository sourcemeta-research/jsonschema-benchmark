import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


if __name__ == "__main__":
    # Average out runtime across runs
    runtime = (
        pd.read_csv("dist/report.csv")
        .groupby(["implementation", "version", "name"])
        .mean()
        .astype("int")
    )
    runtime.reset_index(inplace=True)
    runtime = runtime[runtime['implementation'] == 'blaze']
    runtime.set_index(["name"], inplace=True)

    data = pd.read_csv('dist/summary.csv')
    data.set_index(['name'], inplace=True)
    joined = runtime.join(data, on='name')

    fig, ax = plt.subplots()
    ax.set(xscale='log', yscale='log')
    ax.set_xlabel('Schema size (KB)')
    ax.set_ylabel('Compile time (ns)')
    plot = sns.scatterplot(data=joined, x='size_kb', y='compile_ns')
    plot.get_figure().savefig(
        f"dist/results/compile.png", dpi=96, bbox_inches="tight"
    )
    plot.get_figure().savefig(
        f"dist/results/compile.svg", dpi=96, bbox_inches="tight"
    )