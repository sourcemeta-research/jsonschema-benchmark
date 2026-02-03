from collections import defaultdict
import csv

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


IMPL_RENAMES = {
    'ajv-bun': 'ajv',
    'blaze': 'Blaze',
    'boon': 'Boon',
    'corvus': 'Corvus',
    'go-jsonschema': 'jsonschema (Go)',
    'jsdotnet': 'JsonSchema.Net',
    'jsv': 'JSV',
    'kmp': 'KMP',
    'networknt': 'NetworkNT',
    'py-jsonschema': 'jsonschema (Py)',
}

PLOT_ORDER = ['Compile', 'Cold', 'Warm']

PLOT_COLORS = ['midnightblue', 'lightsteelblue', 'orangered']


if __name__ == "__main__":
    data = pd.read_csv('dist/report.csv')

    # Exclude implementations we are not comparing
    data = data[~data['implementation'].isin(['ajv-bun', 'hyperjump', 'opis'])]
    data['implementation'] = data['implementation'].replace(IMPL_RENAMES)

    # Get schemas that fail on at least one implementation
    exclude_schemas = set(data[data['exit_status'] != 0]['name'].unique())

    # Remove columns we no longer need
    data['compile_ms'] = data['compile_ns'] / 1e9
    data['cold_ms'] = data['cold_ns'] / 1e6
    data['warm_ms'] = data['warm_ns'] / 1e6
    data.drop(['version', 'cold_ns', 'warm_ns', 'compile_ns', 'memory', 'exit_status'], axis=1, inplace=True)

    # Keep only schemas that have not failed
    data = data[~data['name'].isin(exclude_schemas)]

    # Add an index for each run
    data['run'] = data.groupby(['implementation', 'name']).cumcount()

    # Get the total across schemas for each run
    data = data.groupby(['implementation', 'run']).sum()

    # Remove the schema name that we no longer need
    data.drop(['name'], axis=1, inplace=True)
    data = data.reset_index()

    # Reformat the data frame
    data.rename(columns={'cold_ms': 'Cold', 'warm_ms': 'Warm', 'compile_ms': 'Compile'}, inplace=True)
    data = data.melt(
        id_vars=["implementation"], value_vars=("Cold", "Warm", "Compile")
    )

    data.rename(columns={"variable": "Run type"}, inplace=True)
    data = data.sort_values('implementation', key=lambda col: col.str.lower())
    fig, ax1 = plt.subplots(figsize=(6, 4), dpi=96)

    # Configure the y axis
    ax1.set(yscale='log')
    ax1.set_ylabel("Validation time (ms)")

    # Make a copy of the y-axis to plot compilation time
    ax2 = ax1.twinx()
    ax2.set(yscale='log')
    ax2.set_ylabel("Compilation time (s)")

    # Zero out compilation time for the first plot
    data1 = data.copy()
    data1.loc[data1['Run type'] == 'Compile', ['value']] = 0

    plot = sns.barplot(data1, x="implementation", y="value", hue="Run type", ax=ax1, hue_order=PLOT_ORDER, palette=PLOT_COLORS)

    # Configure the x axis
    plot.set(xlabel=None)
    plot.tick_params(axis="x", rotation=50)
    plt.tight_layout()

    # Zero out cold and warm runs for the compilation time plot
    data2 = data.copy()
    data2.loc[data1['Run type'] == 'Cold', ['value']] = 0
    data2.loc[data1['Run type'] == 'Warm', ['value']] = 0

    # Plot compilation time on the second axis, removing the duplicate legend
    plot = sns.barplot(data2, x="implementation", y="value", hue="Run type", ax=ax2, hue_order=PLOT_ORDER, palette=PLOT_COLORS)
    plot.legend().remove()

    plot.get_figure().savefig(
        f"dist/results/plot-all.png", dpi=96, bbox_inches="tight"
    )
    plot.get_figure().savefig(
        f"dist/results/plot-all.svg", dpi=96, bbox_inches="tight"
    )
    plt.clf()
