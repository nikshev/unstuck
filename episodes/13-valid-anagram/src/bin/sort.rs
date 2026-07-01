use std::time::Instant;

// SORT approach: sort both strings' characters and compare. O(n log n).
fn is_anagram(a: &str, b: &str) -> bool {
    let mut x: Vec<char> = a.chars().collect();
    let mut y: Vec<char> = b.chars().collect();
    x.sort();
    y.sort();
    x == y
}

fn main() {
    for (a, b) in [("anagram", "nagaram"), ("rat", "car"), ("listen", "silent")] {
        println!("{:8} vs {:8} -> {}", a, b, is_anagram(a, b));
    }
    let big_a: String = "abcdefghij".repeat(100_000);          // 1,000,000 chars
    let big_b: String = big_a.chars().rev().collect();
    let t = Instant::now();
    let r = is_anagram(&big_a, &big_b);
    println!("1,000,000 chars sort  O(n log n) -> {} in {:?}", r, t.elapsed());
}
