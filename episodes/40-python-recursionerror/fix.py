# app.py -- factorial, and the base case that bites
def factorial(n):
    # n! = n * (n-1) * ... * 1,  and 0! is defined as 1
    if n <= 1:                   # THE FIX: reachable from 0 and 1 (guards negatives too)
        return 1
    return n * factorial(n - 1)


# Bulletproof for HUGE n: iterate. Recursion is capped ~1000 deep no matter what.
def factorial_iter(n):
    result = 1
    for k in range(2, n + 1):
        result *= k
    return result


print("0! =", factorial(0))      # 1  -> the base-case bug is gone
print("5! =", factorial(5))      # 120
print("1400! has", len(str(factorial_iter(1400))), "digits (iteration beats the depth limit)")
