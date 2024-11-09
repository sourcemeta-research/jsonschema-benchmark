from collections import defaultdict
import csv
import sys

reader = csv.DictReader(open('dist/report.csv'))
min_val = defaultdict(lambda: sys.maxsize)
min_impl = {}
for row in reader:
    # Skip failed runs
    if row['exit_status'] != '0':
        continue

    if int(row['cold_ns']) < min_val[row['name']]:
        min_val[row['name']] = int(row['cold_ns'])
        min_impl[row['name']] = row['implementation']

reader = csv.DictReader(open('dist/report.csv'))
next_min_val = defaultdict(lambda: sys.maxsize)
for row in reader:
    # Skip failed runs
    if row['exit_status'] != '0':
        continue

    if int(row['cold_ns']) > min_val[row['name']] \
            and int(row['cold_ns']) < next_min_val[row['name']]:
        next_min_val[row['name']] = int(row['cold_ns'])

reader = csv.DictReader(open('dist/report.csv'))
writer = csv.DictWriter(sys.stdout, fieldnames=row.keys())
writer.writeheader()
for row in reader:
    row_emoji = ''
    if min_impl[row['name']] == row['implementation']:
        row_emoji += ' :white_check_mark:'
        if min_val[row['name']] <= next_min_val[row['name']] * 0.8:
            row_emoji += ' :trophy:'
    if row['exit_status'] != '0':
        row_emoji += ' :x:'

    row['name'] += row_emoji
    writer.writerow(row)
