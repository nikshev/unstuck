from b import helper_b          # a imports b at load time

GREETING = "hello from a"

def helper_a():
    return "helper_a -> " + helper_b()
