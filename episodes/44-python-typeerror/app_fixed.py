# app.py -- add up the numbers a user typed in  (FIXED)
prices = [10, 5, "3", 2]

total = 0
for p in prices:
    total = total + int(p)   # THE FIX: convert at the boundary -- int(p) turns "3" into 3

print(f"total: {total}")

# Bonus: the OTHER place this bites -- building a message.
count = 3
# print("items: " + count)          # TypeError: can only concatenate str (not "int") to str
print("items: " + str(count))       # fix 1: str(count)
print(f"items: {count}")            # fix 2 (better): an f-string
