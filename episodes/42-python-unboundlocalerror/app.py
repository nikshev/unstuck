# app.py -- a running counter for how many requests we've handled
count = 0

def handle_request():
    count += 1                        # `count += 1` READS then WRITES count
    print(f"handled request #{count}")


handle_request()
