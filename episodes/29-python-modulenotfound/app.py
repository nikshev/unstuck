# app.py

import requests  # a third-party package (might not be installed here)


def get(url: str) -> int:
    # return the HTTP status code for a URL
    resp = requests.get(url)  # send an HTTP GET request to the URL
    return resp.status_code   # hand back the numeric status (200, 404, ...)


print(get("https://example.com"))
