use std::time::Instant;

// O(n log n): split in half, sort each, merge the two sorted halves
fn merge_sort(a: &[i32]) -> Vec<i32> {
    if a.len() <= 1 {
        return a.to_vec();
    }
    let mid = a.len() / 2;
    let left = merge_sort(&a[..mid]);
    let right = merge_sort(&a[mid..]);
    merge(&left, &right)
}

fn merge(l: &[i32], r: &[i32]) -> Vec<i32> {
    let mut out = Vec::with_capacity(l.len() + r.len());
    let (mut i, mut j) = (0, 0);
    while i < l.len() && j < r.len() {
        if l[i] <= r[j] {
            out.push(l[i]); i += 1;
        } else {
            out.push(r[j]); j += 1;
        }
    }
    out.extend_from_slice(&l[i..]);
    out.extend_from_slice(&r[j..]);
    out
}

fn main() {
    let v: Vec<i32> = (0..30_000).rev().collect();
    let t = Instant::now();
    let sorted = merge_sort(&v);
    println!("merge sort   O(n log n): sorted {} items in {:?}", sorted.len(), t.elapsed());
}
