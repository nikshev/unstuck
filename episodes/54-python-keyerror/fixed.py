config = {"host": "localhost", "port": 8080}

def get_timeout(cfg):
    return cfg.get("timeout", 30)   # .get() returns a default instead of raising

# other safe patterns:
#   if "timeout" in cfg: ...        (check first)
#   from collections import defaultdict
print("timeout is", get_timeout(config))
