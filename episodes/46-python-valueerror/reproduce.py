# reproduce.py -- total up quantities that were read as text
# (values arrive as STRINGS: from input(), a CSV cell, JSON, a web form...)
rows = ["3", "10", "12.5"]     # note: "12.5" came in as a decimal string

total = 0
for q in rows:
    total = total + int(q)     # int("12.5") -> ValueError: invalid literal for int()

print(f"total: {total}")
