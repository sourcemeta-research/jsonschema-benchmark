import pandas as pd

# Average out runtime across runs
data = (
    pd.read_csv("dist/report.csv")
    .groupby(["implementation", "version", "name"])
    .mean()
    .astype("int")
)
data['cold_ms'] = data['cold_ns'] / 1e6
data['warm_ms'] = data['warm_ns'] / 1e6
data.reset_index(inplace=True)
data.set_index(["implementation", "name"], inplace=True)

# Get the fastest implementations
min_cold_impls = set()
for impl, schema in data[data["exit_status"] == 0].groupby("name")["cold_ms"].idxmin():
    min_cold_impls.add((schema, impl))
min_warm_impls = set()
for impl, schema in data[data["exit_status"] == 0].groupby("name")["warm_ms"].idxmin():
    min_warm_impls.add((schema, impl))

IMPL_RENAMES = {
    'ajv-bun': 'ajv',
    'blaze': 'Blaze',
    'boon': 'Boon',
    'corvus': 'Corvus',
    'go-jsonschema': 'jsonschema (Go)',
    'hyperjump': 'Hyperjump',
    'jsonschemadotnet': 'JsonSchema.Net',
    'kmp-json-schema-validator': 'KMP',
    'networknt': 'NetworkNT',
    'opis': 'Opis',
    'python-jsonschema': 'jsonschema (Py)',
}

impls = list(data.index.get_level_values(0).unique().drop('ajv').values)
impls.sort(key=lambda x: IMPL_RENAMES.get(x, x).lower())

cols = "|".join("c" * (len(impls) + 1))
print(r"""
    \begin{tabular}{|""" + cols + r"""|}
        \hline
        \textbf{Dataset} & """)

print('        ', end='')
for (i, impl) in enumerate(impls):
    if i != 0:
        print("& ", end='')
    impl = impl.replace('_', '\\_')
    impl = IMPL_RENAMES.get(impl, impl)
    print(f"\\textbf{{{impl}}} ", end='')
print(r'\\\hline')

DATASET_RENAMES = {
    'gitpod-configuration': 'gitpod',
    'pre-commit-hooks': 'pre-commit',
    'unreal-engine-uproject': 'unreal'
}

for dataset in data.index.get_level_values(1).unique():
    if dataset in {'example'}:
        continue

    dataset_name = DATASET_RENAMES.get(dataset, dataset)
    print(f"        \\multirow{{2}}{{*}}{{{dataset_name}}}", end='')

    # Print cold run times
    for impl in impls:
        datum = data.loc[(impl, dataset)]
        if datum['exit_status'] == 0:
            runtime = f"{datum['cold_ms']:.1f}"
        else:
            runtime = r'\textdagger'
        if (dataset, impl) in min_cold_impls:
            runtime = f"\\textbf{{{runtime}}}"
        print(f" & \\multicolumn{{1}}{{c|}}{{{runtime}}}", end='')
    print(r'\\\cline{2-' + str(len(impls) + 1) + '}', end='')

    # Print warm run times
    for impl in impls:
        datum = data.loc[(impl, dataset)]
        if datum['exit_status'] == 0:
            runtime = f"{datum['warm_ms']:.1f}"
        else:
            runtime = r'\textdagger'
        if (dataset, impl) in min_warm_impls:
            runtime = f"\\textbf{{{runtime}}}"
        print(f" & \\multicolumn{{1}}{{c|}}{{{runtime}}}", end='')
    print(r'\\\hline')

# Print footer
print(r"""    \end{tabular}""")
