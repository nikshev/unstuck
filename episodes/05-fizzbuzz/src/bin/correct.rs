fn main() {
    for n in 1..=15 {
        // FIX: check the most specific case (divisible by BOTH) first
        if n % 15 == 0 {
            println!("{n}: FizzBuzz");
        } else if n % 3 == 0 {
            println!("{n}: Fizz");
        } else if n % 5 == 0 {
            println!("{n}: Buzz");
        } else {
            println!("{n}: {n}");
        }
    }
}
