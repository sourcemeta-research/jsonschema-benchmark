#!/bin/bash

unset LC_NUMERIC

if [ $# -ne 1 ]; then
  echo "Usage: $0 csv|md"
  exit
fi

FORMAT=$1
SCHEMAS=$(ls schemas/)

LATEX_ROWS=""

# Output each table row
for schema in $SCHEMAS; do
  make "schemas/$schema/schema-noformat.json" > /dev/null || echo "schemas/$schema/schema-noformat.json generation failed" >&2
  docs=$(wc -l < "schemas/$schema/instances.jsonl")
  size=$(jsonschema-strip "schemas/$schema/schema-noformat.json" 2> /dev/null | wc -c)
  # use initial schema size instead, eg noformat is empty or jsonschema-strip is not found
  if [ $size -eq 0 ] ; then
    echo "working around 0 noformat size in $schema" >&2
    size=$(cat "schemas/$schema/schema.json" | wc -c)
  fi
  size_kb=$(bc <<<"scale=1; $size / 1024")
  avg_doc_size=$(cat "schemas/$schema/instances.jsonl" | while read l; do echo "$l" | wc -c; done | awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')

  if [ "$FORMAT" = "csv" ]; then
    CSV_ROWS=$(printf "%s%s,%d,%.1f,%.0f%s" "$CSV_ROWS" "$schema" "$docs" "$size_kb" "$avg_doc_size" '\n')
  elif [ "$FORMAT" = "md" ]; then
    LATEX_ROWS=$(printf "%s        %s & %d & %.1f & %.0f %s" "$LATEX_ROWS" "$schema" "$docs" "$size_kb" "$avg_doc_size" '\\\\\n')
    MARKDOWN_ROWS=$(printf "%s| %s | %d | %.1f | %.0f |%s" "$MARKDOWN_ROWS" "$schema" "$docs" "$size_kb" "$avg_doc_size" '\n')
  fi
done

if [ "$FORMAT" = "csv" ]; then
  cat << EOF
name,docs,size_kb,avg_doc_size
EOF

  echo -ne "$CSV_ROWS"
fi

if [ "$FORMAT" = "md" ]; then
  # Print the table header
  cat << EOF
|Dataset name|# Docs|Schema Size (KB)|Avg. Doc. Size (B)|
|---|---|---|---|
EOF

  echo -e $MARKDOWN_ROWS

  cat << EOF
<details>

<summary>LaTeX table</summary>

EOF

  echo '```'

  cat << EOF
\begin{table}[h]
    {\small
    \centering
    \begin{tabular}{l r r r}
        \hline
        Name & \# Docs & Schema Size (KB) & Avg. Doc. Size (B) \\\\
        \hline
EOF

  echo -ne "$LATEX_ROWS"

  # Print the table footer
  cat << EOF
    \end{tabular}
    }
    \caption{Datasets used for validator evaluation}\label{tab:datasets}
\end{table}
EOF

  echo '```'

  cat << EOF
</details>
EOF
fi
