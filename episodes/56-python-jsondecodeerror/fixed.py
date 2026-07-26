import json

raw = '{\n  "host": "localhost",\n  "port": 8080,\n}'   # same broken input from the wild

def load_config(text):
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        # tells you EXACTLY where: line, column, char index
        print(f"bad JSON at line {e.lineno} col {e.colno}: {e.msg}")
        return {"host": "localhost", "port": 8080}   # safe fallback

config = load_config(raw)
print("port is", config["port"])
