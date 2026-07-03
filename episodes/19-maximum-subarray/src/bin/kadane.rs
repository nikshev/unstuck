use std::time::Instant;

// KADANE O(n): keep a running sum; drop it whenever it turns negative.
fn max_subarray(nums: &[i64]) -> i64 {
    let mut current = 0;         // sum of the run ENDING at this element
    let mut best = i64::MIN;     // best sum ever seen (NOT 0 — that breaks all-negative)
    for &x in nums {
        current += x;            // extend the current run by x
        best = best.max(current);// record it if it's the best so far
        if current < 0 {         // a negative running sum only drags the future down
            current = 0;         // so throw it away and start fresh
        }
    }
    best
}

fn main() {
    let demo = [-2, 1, -3, 4, -1, 2, 1, -5, 4];
    println!("array: {:?}", demo);
    println!("kadane max subarray sum = {}", max_subarray(&demo));

    let allneg = [-8, -3, -6, -2, -5];
    println!("all-negative {:?} -> {}", allneg, max_subarray(&allneg));

    let big: Vec<i64> = (0..30_000).map(|i| ((i * 7 % 13) as i64) - 6).collect();
    let t = Instant::now();
    let r = max_subarray(&big);
    println!("kadane O(n) on {} elems: {} in {:?}", big.len(), r, t.elapsed());
}
