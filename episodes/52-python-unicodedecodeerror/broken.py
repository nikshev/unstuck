# broken.py -- read a config file that is NOT UTF-8 (it has a Latin-1 "é" = byte 0xE9)
with open("data/config.txt") as f:          # text mode defaults to UTF-8
    print(f.read())                          # UnicodeDecodeError: 0xe9 is not valid UTF-8
