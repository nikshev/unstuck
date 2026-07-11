users = {"alice": 30, "bob": 25}

# Fix: ask the dict with .get() and a default, instead of indexing directly.
def get_age(name):
    return users.get(name, 0)   # missing key -> returns 0, no crash

print(get_age("alice"))         # 30
print(get_age("carol"))         # 0  (no KeyError)
