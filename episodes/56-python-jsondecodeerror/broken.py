import json

# config.json was hand-edited and left a trailing comma after the last value.
# JSON does NOT allow trailing commas (unlike Python dicts) -> it's invalid.
raw = '{\n  "host": "localhost",\n  "port": 8080,\n}'

config = json.loads(raw)          # JSONDecodeError: Expecting property name ...
print("port is", config["port"])
