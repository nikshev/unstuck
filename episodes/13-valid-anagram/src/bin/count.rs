use std::time::Instant;

// COUNT approach: one tally per letter. +1 for a, -1 for b; all zero => anagram. O(n).
// Uses a fixed [i32; 26] for lowercase a-z (use a HashMap for arbitrary Unicode).
fn is_anagram(a: &str, b: &str) -> bool {
    if a.len() != b.len() { return false; }
    let mut counts = [0i32; 26];
    for c in a.bytes() { counts[(c - b'a') as usize] += 1; }
    for c in b.bytes() { counts[(c - b'a') as usize] -= 1; }
    counts.iter().all(|&v| v == 0)
}

fn main() {
    for (a, b) in [("anagram", "nagaram"), ("rat", "car"), ("listen", "silent")] {
        println!("{:8} vs {:8} -> {}", a, b, is_anagram(a, b));
    }
    let big_a: String = "abcdefghij".repeat(100_000);
    let big_b: String = big_a.chars().rev().collect();
    let t = Instant::now();
    let r = is_anagram(&big_a, &big_b);
    println!("1,000,000 chars count O(n)       -> {} in {:?}", r, t.elapsed());
}
