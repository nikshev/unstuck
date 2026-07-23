from a import GREETING          # circular: a is still loading, GREETING not defined yet

def helper_b():
    return "helper_b uses [" + GREETING + "]"
