def helper_b():
    from a import GREETING      # deferred: import inside the function, after modules finish loading
    return "helper_b uses [" + GREETING + "]"
