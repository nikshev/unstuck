fn main() {
    for n in 1..=15 {
        // Order-proof: build the word, no overlap bug possible
        let mut s = String::new();
        if n % 3 == 0 { s.push_str("Fizz"); }
        if n % 5 == 0 { s.push_str("Buzz"); }
        if s.is_empty() { s = n.to_string(); }
        println!("{n}: {s}");
    }
}
