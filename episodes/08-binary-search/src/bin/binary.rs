use std::time::Instant;

// O(log n): halve the search range each step (array must be SORTED)
fn main() {
    let v: Vec<i64> = (0..10_000_000).collect();
    let target = 9_999_999;
    let mut comparisons = 0u64;
    let (mut lo, mut hi) = (0usize, v.len()); // hi is EXCLUSIVE
    let t = Instant::now();
    let mut found = None;
    while lo < hi {
        let mid = lo + (hi - lo) / 2; // avoids (lo+hi) overflow
        comparisons += 1;
        if v[mid] == target { found = Some(mid); break; }
        else if v[mid] < target { lo = mid + 1; }
        else { hi = mid; }
    }
    println!("binary search  O(log n): index {:?}, {} comparisons, {:?}", found, comparisons, t.elapsed());
}
