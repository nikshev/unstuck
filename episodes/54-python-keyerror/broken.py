# A config dict loaded from somewhere; "timeout" was never set.
config = {"host": "localhost", "port": 8080}

def get_timeout(cfg):
    return cfg["timeout"]        # square-bracket lookup REQUIRES the key to exist

print("timeout is", get_timeout(config))
