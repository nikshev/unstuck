use std::time::Instant;

// O(n^2): compare every pair
fn has_duplicate(v: &[i64]) -> bool {
    for i in 0..v.len() {
        for j in (i + 1)..v.len() {
            if v[i] == v[j] { return true; }
        }
    }
    false
}

fn main() {
    let mut v: Vec<i64> = (0..30_000).collect();
    v.push(v[v.len() - 1]); // duplicate the last value (worst case to find)
    let t = Instant::now();
    let dup = has_duplicate(&v);
    println!("brute force  O(n^2): duplicate? {}  in {:?}", dup, t.elapsed());
}
