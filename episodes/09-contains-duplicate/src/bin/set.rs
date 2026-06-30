use std::collections::HashSet;
use std::time::Instant;

// O(n): remember what we've seen; HashSet::insert returns false if already present
fn has_duplicate(v: &[i64]) -> bool {
    let mut seen = HashSet::new();
    for &x in v {
        if !seen.insert(x) { return true; }
    }
    false
}

fn main() {
    let mut v: Vec<i64> = (0..30_000).collect();
    v.push(v[v.len() - 1]);
    let t = Instant::now();
    let dup = has_duplicate(&v);
    println!("hash set     O(n):   duplicate? {}  in {:?}", dup, t.elapsed());
}
