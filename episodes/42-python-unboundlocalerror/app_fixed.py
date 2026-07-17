# app.py -- a running counter for how many requests we've handled
count = 0

def handle_request():
    global count                      # THE FIX: `count` is the module-level variable
    count += 1
    print(f"handled request #{count}")


handle_request()
handle_request()

# Cleaner: no global at all -- take the value in, hand a new one back.
def handle(n):
    return n + 1

total = 0
total = handle(total)
total = handle(total)
print(f"no-globals version -> {total}")
