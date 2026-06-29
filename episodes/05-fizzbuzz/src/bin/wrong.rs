fn main() {
    for n in 1..=15 {
        // BUG: order is wrong — 15 is divisible by 3, so it never reaches FizzBuzz
        if n % 3 == 0 {
            println!("{n}: Fizz");
        } else if n % 5 == 0 {
            println!("{n}: Buzz");
        } else if n % 15 == 0 {
            println!("{n}: FizzBuzz");
        } else {
            println!("{n}: {n}");
        }
    }
}
