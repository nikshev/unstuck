# reproduce.py — a tiny user store
def build_user(name, email):
    # build a user record and hand it back to the caller
    user = {"name": name, "email": email, "active": True}
    # BUG: we built the dict but never returned it -> build_user returns None


def greet(user):
    return "Hello, " + user.get("name")   # greet needs a real user dict


u = build_user("Ada Lovelace", "ada@example.com")   # u is None (nothing was returned)
print(greet(u))                                     # 'NoneType' object has no attribute 'get'
