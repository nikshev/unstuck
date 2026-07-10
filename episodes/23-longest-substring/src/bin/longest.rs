use std::collections::HashMap;

// ❌ Brute force: check EVERY starting point, extend while characters stay unique. O(n^2).
fn longest_brute(s: &str) -> usize {
    let b = s.as_bytes();
    let mut best = 0;
    for i in 0..b.len() {
        let mut seen = [false; 256];         // which bytes are in the current run
        let mut len = 0;
        for j in i..b.len() {
            if seen[b[j] as usize] { break; } // repeat -> this run ends
            seen[b[j] as usize] = true;
            len += 1;
        }
        best = best.max(len);
    }
    best
}

// ✅ Sliding window: one pass. Grow the window on the right; when a char repeats,
// jump the LEFT edge just past where we last saw it. O(n).
fn longest(s: &str) -> usize {
    let b = s.as_bytes();
    let mut last: HashMap<u8, usize> = HashMap::new(); // char -> last index seen
    let mut left = 0;
    let mut best = 0;
    for right in 0..b.len() {
        if let Some(&p) = last.get(&b[right]) {
            if p >= left {
                left = p + 1;                 // shrink: move left past the duplicate
            }
        }
        last.insert(b[right], right);
        best = best.max(right - left + 1);    // current window size
    }
    best
}

fn main() {
    let tests = ["abcabcbb", "bbbbb", "pwwkew", "dvdf", "abba", ""];
    println!("input      brute  window");
    for t in tests {
        println!("{:9}  {:5}  {:6}", format!("{:?}", t), longest_brute(t), longest(t));
    }
}
