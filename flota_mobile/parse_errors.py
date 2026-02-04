import re

with open('analyze_errors.txt', 'r', encoding='utf8') as f:
    lines = f.readlines()

errors = []
for line in lines:
    if 'error - ' in line:
        errors.append(line.strip())

# Deduplicate by content before the file path if needed, but let's just see them all first.
for err in errors:
    print(err)
