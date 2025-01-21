#!/bin/bash

SCHEMAS=$(ls schemas/)

LATEX_ROWS=""

# Output each table row
for schema in $SCHEMAS; do
  docs=$(wc -l < "schemas/$schema/instances.jsonl")
  size=$(wc -c < "schemas/$schema/schema.json")
  size_kb=$(bc <<<"scale=1; $size / 1024")
  avg_doc_size=$(cat "schemas/$schema/instances.jsonl" | while read l; do echo "$l" | wc -c; done | awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')

  LATEX_ROWS=$(printf "%s        %s & %d & %.1f & %.0f %s" "$LATEX_ROWS" "$schema" "$docs" "$size_kb" "$avg_doc_size" '\\\\\n')
  MARKDOWN_ROWS=$(printf "%s| %s | %d | %.1f | %.0f |%s" "$MARKDOWN_ROWS" "$schema" "$docs" "$size_kb" "$avg_doc_size" '\n')
done

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
    \caption{Dataset used for validator evaluation}\label{tab:datasets}
\end{table}
EOF

echo '```'

cat << EOF
</details>
EOF
