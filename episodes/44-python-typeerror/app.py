# app.py -- add up the numbers a user typed in
# (values often arrive as STRINGS: from input(), a CSV, a web form, JSON...)
prices = [10, 5, "3", 2]     # note: "3" came in as text, not a number

total = 0
for p in prices:
    total = total + p        # int + str  ->  TypeError as soon as p == "3"

print(f"total: {total}")
