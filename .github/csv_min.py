from collections import defaultdict
import csv
import sys

reader = csv.DictReader(open('dist/report.csv'))
min_val = defaultdict(lambda: sys.maxsize)
min_impl = {}
for row in reader:
    if int(row['nanoseconds']) < min_val[row['name']]:
        min_val[row['name']] = int(row['nanoseconds'])
        min_impl[row['name']] = row['implementation']

reader = csv.DictReader(open('dist/report.csv'))
writer = csv.DictWriter(sys.stdout, fieldnames=row.keys())
writer.writeheader()
for row in reader:
    if min_impl[row['name']] == row['implementation']:
        row['name'] += ' :white_check_mark:'
    writer.writerow(row)
