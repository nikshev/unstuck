# app.py
nums = [10, 20, 30]


def print_all(items):
    # print every element of the list, one per line
    for i in range(len(items) + 1):  # BUG: + 1 makes it walk one PAST the end
        print(items[i])              # items[3] doesn't exist -> IndexError


print_all(nums)
