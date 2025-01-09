#!/bin/bash

SCHEMAS=$(ls schemas/)

# Print the table header
cat << EOF
\begin{table}[h]
    {\small
    \centering
    \begin{tabular}{l r r r}
        \hline
        Name & \# Docs & Schema Size (KB) & Avg. Doc. Size (B) \\
        \hline
EOF

# Output each table row
for schema in $SCHEMAS; do
  docs=$(wc -l < "schemas/$schema/instances.jsonl")
  size=$(wc -c < "schemas/$schema/schema.json")
  size_kb=$(bc <<<"scale=1; $size / 1024")
  avg_doc_size=$(cat "schemas/$schema/instances.jsonl" | while read l; do echo "$l" | wc -c; done | awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')

  printf "        %s & %d & %.1f & %.0f \\\\\n" "$schema" "$docs" "$size_kb" "$avg_doc_size"
done

# Print the table footer
cat << EOF
    \end{tabular}
    }
    \caption{Dataset used for validator evaluation}\label{tab:datasets}
\end{table}
EOF
