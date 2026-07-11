# Look up a user's age by name.
users = {"alice": 30, "bob": 25}

def get_age(name):
    return users[name]          # direct index: KeyError if name is missing

print(get_age("alice"))         # 30 - fine
print(get_age("carol"))         # 'carol' isn't in users -> KeyError
