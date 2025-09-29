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
    joined['compile_s'] = joined['compile_ns'] / 1e9

    fig, ax = plt.subplots(figsize=(6,3))
    ax.set(xscale='log', yscale='log')
    ax.set_xlabel('Schema size (KB)')
    ax.set_ylabel('Compile time (s)')
    plot = sns.scatterplot(data=joined, x='size_kb', y='compile_s')
    plot.get_figure().savefig(
        f"dist/results/plots/compile.png", dpi=96, bbox_inches="tight"
    )
    plot.get_figure().savefig(
        f"dist/results/plots/compile.svg", dpi=96, bbox_inches="tight"
    )
