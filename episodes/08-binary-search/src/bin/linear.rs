use std::time::Instant;

// O(n): check every element from the start
fn main() {
    let v: Vec<i64> = (0..10_000_000).collect();
    let target = 9_999_999; // near the end = worst case
    let mut comparisons = 0u64;
    let t = Instant::now();
    let mut found = None;
    for (i, &x) in v.iter().enumerate() {
        comparisons += 1;
        if x == target { found = Some(i); break; }
    }
    println!("linear search  O(n):     index {:?}, {} comparisons, {:?}", found, comparisons, t.elapsed());
}
