import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


IMPL_RENAMES = {
    'ajv-bun': 'ajv',
    'blaze': 'Blaze',
    'boon': 'Boon',
    'corvus': 'Corvus',
    'go-jsonschema': 'jsonschema (Go)',
    'jmc': 'JMC (C)',
    'jmc-js': 'JMC (JS)',
    'jmc-pl': 'JMC (Perl)',
    'jmc-py': 'JMC (Python)',
    'jsdotnet': 'JsonSchema.Net',
    'jsv': 'JSV',
    'kmp': 'KMP',
    'networknt': 'NetworkNT',
    'py-jsonschema': 'jsonschema (Py)',
}

if __name__ == "__main__":
    data = pd.read_csv('dist/report.csv')

    # Exclude implementations we are not comparing
    data = data[~data['implementation'].isin(['ajv-bun', 'hyperjump', 'opis'])]
    data['implementation'] = data['implementation'].replace(IMPL_RENAMES)

    # Exclujde any failed implementations
    data = data[data['exit_status'] == 0]

    # Pick only the columns we need
    data = data[['implementation', 'name', 'memory']]

    # Average memory use across runs
    data = (
        data
        .groupby(["implementation", "name"])
        .mean()
        .astype("int")
    )

    # Draw the plot
    fig, ax1 = plt.subplots(figsize=(6, 3), dpi=96)
    sns.set(font_scale=0.5)
    plot = sns.boxplot(data, x='implementation', y='memory')

    # Configure the x axis
    plot.set(xlabel=None)
    plot.tick_params(axis="x", rotation=50)
    plt.tight_layout()

    # Configure the y axis
    ax1.set(yscale='log')
    ax1.set_ylabel("Max memory usage (KB)")

    plot.get_figure().savefig(
        f"dist/results/plots/memory.png", dpi=96, bbox_inches="tight"
    )
    plot.get_figure().savefig(
        f"dist/results/plots/memory.svg", dpi=96, bbox_inches="tight"
    )
