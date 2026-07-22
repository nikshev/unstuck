# reproduce.py -- load the app's config file
# It lives in a data/ subfolder, but we asked for a bare "config.txt",
# so Python looks in the CURRENT WORKING DIRECTORY and doesn't find it.
with open("config.txt") as f:          # FileNotFoundError: [Errno 2] No such file or directory: 'config.txt'
    settings = f.read()

print(settings)
