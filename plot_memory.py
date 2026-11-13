import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


IMPL_RENAMES = {
    'ajv-bun': 'ajv',
    'ata-validator': 'ata',
    'blaze': 'Blaze',
    'boon': 'Boon',
    'corvus-net-optcold': 'Corvus (.NET, AOT)',
    'corvus-net-optwarm': 'Corvus (.NET, JIT)',
    'corvus-ts': 'Corvus (TS)',
    'corvus-rs': 'Corvus (Rust)',
    'corvus-py': 'Corvus (Python)',
    'corvus-py-rs': 'Corvus (Python, Rust)',
    'corvus-cpp': 'Corvus (C++)',
    'corvus-rb': 'Corvus (Ruby)',
    'corvus-php': 'Corvus (PHP)',
    'corvus-swift': 'Corvus (Swift)',
    'corvus-java': 'Corvus (Java)',
    'corvus-go': 'Corvus (Go)',
    'corvus-pas': 'Corvus (Object Pascal)',
    'corvus-r': 'Corvus (R)',
    'corvus-jl': 'Corvus (Julia)',
    'go-jsonschema': 'jsonschema (Go)',
    'jsu-c': 'JSU (C)',
    'jsu-java': 'JSU (Java)',
    'jsu-js': 'JSU (JS)',
    'jsu-pl': 'JSU (Perl)',
    'jsu-py': 'JSU (Python)',
    'jsdotnet': 'JsonSchema.Net',
    'jsv': 'JSV',
    'kmp': 'KMP',
    'networknt': 'NetworkNT',
    'jsonschema-rs': 'jsonschema-rs (Py)',
    'py-jsonschema': 'jsonschema (Py)',
    'corvus-c': 'Corvus (C)',
    'corvus-fortran': 'Corvus (Fortran)',
    'corvus-net-v4': 'Corvus (.NET, V4)',
    'ajv-plus': 'ajv-plus',
    'cfworker': '@cfworker/json-schema',
    'jsonschema-js': 'jsonschema (JS)',
    'json-schema-library': 'json-schema-library',
    'vscode-json-languageservice': 'vscode-json-languageservice',
    'fastjsonschema': 'fastjsonschema',
    'jschon': 'jschon',
    'gojsonschema': 'gojsonschema',
    'justinrainbow': 'justinrainbow/json-schema',
    'json-schema-modern': 'JSON::Schema::Modern',
    'harrel-json-schema': 'json-schema (harrel)',
    'json-schema-react': 'json-schema (georgeakulov)',
    'jsonschemafriend': 'jsonschemafriend',
    'openapiprocessor': 'openapiprocessor',
    'sjf4j': 'sjf4j',
    'valijson': 'valijson',
    'iris': 'IRIS',
    'jsonschex': 'JSONSchex',
    'swift-json-schema': 'swift-json-schema',
    'lua-jsonschema': 'jsonschema (Lua)',
    'lua-schema': 'lua-schema',
    'clojure-json-schema': 'json-schema (Clojure)',
    'scala-json-schema': 'json-schema (Scala)',
    'rc-circe-json-schema': 'rc-circe-json-schema',
    'typed-json': 'typed-json',
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
