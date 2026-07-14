# fix.py — a tiny user store
def build_user(name, email):
    # build a user record and hand it back to the caller
    user = {"name": name, "email": email, "active": True}
    return user                            # THE FIX: actually return the dict


def greet(user):
    return "Hello, " + user.get("name")   # greet needs a real user dict


u = build_user("Ada Lovelace", "ada@example.com")
print(greet(u))                            # -> Hello, Ada Lovelace
