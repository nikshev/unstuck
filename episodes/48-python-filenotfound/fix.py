# fix.py -- load the config safely, no matter where you launch python from
from pathlib import Path

# 1) Anchor the path to THIS file's folder (not the shell's cwd), and point at data/
config_path = Path(__file__).parent / "data" / "config.txt"

# 2) If the file might be missing, handle it instead of crashing
try:
    settings = config_path.read_text()
except FileNotFoundError:
    print(f"no config at {config_path} -- using defaults")
    settings = "theme=dark\nvolume=5\n"

print(settings)
