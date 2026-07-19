# fix.py -- total up quantities that were read as text, safely
rows = ["3", "10", "12.5"]     # a decimal string sneaked in

total = 0
for q in rows:
    q = q.strip()                     # strip stray spaces/newlines (the #1 hidden cause)
    try:
        total = total + int(q)        # the clean path: a plain integer string
    except ValueError:
        total = total + int(float(q)) # "12.5" -> 12.5 -> 12  (int() won't parse a decimal)

print(f"total: {total}")             # 3 + 10 + 12 = 25
