# app.py -- factorial, and the base case that bites
def factorial(n):
    # n! = n * (n-1) * ... * 1,  and 0! is defined as 1
    if n == 1:                   # base case... but ONLY for exactly 1
        return 1
    return n * factorial(n - 1)


print("5! =", factorial(5))      # works: 5 -> 4 -> 3 -> 2 -> 1, base case hit
print("0! =", factorial(0))      # BOOM: 0 -> -1 -> -2 -> ...  never reaches 1
