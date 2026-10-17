"""Builds the interactive results site from report.csv (and, when present, the dataset summary).

The site is one self-contained HTML file: the measurements are embedded as JSON and the charts are drawn in the
browser, so it can be uploaded as an artifact, copied to a bucket or served from GitHub Pages as it is. The same data
is written beside it as data.json, described by site/data.schema.json, for other sites to build on.

Usage (after report.csv and summary.csv are in dist/, as the aggregate job leaves them):
    uv run python site/generate_site.py --repo "$GITHUB_REPOSITORY" --commit "$GITHUB_SHA" --run-url "$RUN_URL" \
        --date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --runner "Azure runner pool"
"""

import argparse
import csv
import json
import os
from collections import Counter, defaultdict

# The language of an implementation is read from the files in its directory, so a new implementation needs no change
# here: the language with the most source files wins, and a directory without source files falls back to its build
# manifest.
SOURCE_LANGUAGES = {
    ".c": "C", ".cc": "C++", ".cpp": "C++", ".cxx": "C++", ".cs": "C#", ".ex": "Elixir", ".exs": "Elixir",
    ".go": "Go", ".java": "Java", ".js": "JavaScript", ".mjs": "JavaScript", ".cjs": "JavaScript",
    ".ts": "JavaScript", ".kt": "Kotlin", ".pas": "Object Pascal", ".pl": "Perl", ".php": "PHP", ".py": "Python",
    ".r": "R", ".rb": "Ruby", ".rs": "Rust", ".swift": "Swift",
}
MANIFEST_LANGUAGES = {
    "package.json": "JavaScript", "Cargo.toml": "Rust", "go.mod": "Go", "pom.xml": "Java", "Gemfile": "Ruby",
    "composer.json": "PHP", "pyproject.toml": "Python", "Package.swift": "Swift", "mix.exs": "Elixir",
}
# Dependency and build output folders, whose files are not the implementation's own.
SKIP_FOLDERS = {"node_modules", "target", "build", "gradle", ".gradle", "vendor", "deps", "_build"}


def language_of(folder):
    counts = Counter()
    manifest = ""
    for root, folders, files in os.walk(folder):
        folders[:] = [f for f in folders if f not in SKIP_FOLDERS]
        for name in files:
            language = SOURCE_LANGUAGES.get(os.path.splitext(name)[1].lower())
            if language:
                counts[language] += 1
            manifest = manifest or MANIFEST_LANGUAGES.get(name, "")
    if counts:
        return max(sorted(counts), key=counts.get)
    return manifest


# Raised when data.json changes in a way its readers must handle.
DATA_VERSION = 1

TEMPLATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "template.html")


def read_report(path):
    runs = defaultdict(list)
    versions = {}
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            impl, schema = row["implementation"], row["name"]
            versions[impl] = row["version"]
            runs[(impl, schema)].append(row)

    results = defaultdict(dict)
    for (impl, schema), rows in runs.items():
        if any(int(r["exit_status"]) != 0 for r in rows):
            # A run that failed to validate any instance makes every figure for the schema meaningless.
            results[impl][schema] = None
            continue
        results[impl][schema] = {
            "cold": [int(r["cold_ns"]) for r in rows],
            "warm": [int(r["warm_ns"]) for r in rows],
            "compile": [int(r["compile_ns"]) for r in rows],
            "parse": [int(r["parse_ns"]) for r in rows],
            "memory": [int(r["memory"]) for r in rows],
        }
    return results, versions


def bowtie_id_of(folder):
    """The implementation's Bowtie ID, from the optional one-line `bowtie` file in its directory."""
    path = os.path.join(folder, "bowtie")
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        return f.read().strip() or None


def dialect_of(folder):
    """The dialect a schema declares through its `$schema`, if any."""
    try:
        with open(os.path.join(folder, "schema.json"), encoding="utf-8") as f:
            schema = json.load(f)
    except (OSError, ValueError):
        return None
    return schema.get("$schema") if isinstance(schema, dict) else None


def read_summary(path):
    if not path or not os.path.exists(path):
        return {}
    with open(path, newline="") as f:
        return {
            row["name"]: {
                "docs": int(row["docs"]),
                "sizeKb": float(row["size_kb"]),
                "avgDoc": float(row["avg_doc_size"]),
            }
            for row in csv.DictReader(f)
        }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", default="dist/report.csv")
    parser.add_argument("--summary", default="dist/summary.csv")
    parser.add_argument("--out", default="dist/site/index.html")
    parser.add_argument("--repo", default="sourcemeta-research/jsonschema-benchmark")
    parser.add_argument("--implementations", default="implementations")
    parser.add_argument("--schemas", default="schemas")
    parser.add_argument("--run-url", default="")
    parser.add_argument("--commit", default="")
    parser.add_argument("--date", default="")
    parser.add_argument("--runner", default="")
    # For hosts that supply the document skeleton themselves, such as a preview that wraps the page.
    parser.add_argument("--fragment", action="store_true", help="Emit the page without its document skeleton.")
    args = parser.parse_args()

    results, versions = read_report(args.report)
    summary = read_summary(args.summary)
    schemas = sorted({s for per_impl in results.values() for s in per_impl})

    impls = [
        {
            "id": impl,
            "name": impl,
            "lang": language_of(os.path.join(args.implementations, impl)),
            "version": versions[impl],
            "bowtie": bowtie_id_of(os.path.join(args.implementations, impl)),
        }
        for impl in sorted(results)
    ]

    # The page's data, also written as data.json beside it for other sites to use (see site/data.schema.json).
    data = {
        "version": DATA_VERSION,
        "meta": {
            "repo": args.repo,
            "runUrl": args.run_url,
            "commit": args.commit,
            "date": args.date,
            "runner": args.runner,
            "runs": max((len(v["warm"]) for r in results.values() for v in r.values() if v), default=0),
        },
        "impls": impls,
        "schemas": [
            {"name": s, "dialect": dialect_of(os.path.join(args.schemas, s)), **summary.get(s, {})} for s in schemas
        ],
        "results": results,
    }

    payload = json.dumps(data, separators=(",", ":")).replace("</", "<\\/")
    with open(TEMPLATE, encoding="utf-8") as f:
        page = f.read().replace("/*BENCHMARK_DATA*/null", payload)
    if not args.fragment:
        head, body = page.split("<header", 1)
        page = (
            '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
            f"{head}</head>\n<body>\n<header{body}</body>\n</html>\n"
        )

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(page)
    with open(os.path.join(os.path.dirname(os.path.abspath(args.out)), "data.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))


if __name__ == "__main__":
    main()
