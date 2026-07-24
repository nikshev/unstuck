# fixed.py -- open with the file's ACTUAL encoding (Latin-1 / cp1252)
with open("data/config.txt", encoding="latin-1") as f:
    print(f.read())                          # decodes cleanly: café
