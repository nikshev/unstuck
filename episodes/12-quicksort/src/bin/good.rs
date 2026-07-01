// Quicksort with a better pivot: the MIDDLE element.
// Balanced partitions → O(n log n) even on sorted input.
fn quicksort(v: &[i32], comparisons: &mut u64) -> Vec<i32> {
    if v.len() <= 1 { return v.to_vec(); }
    let mid = v.len() / 2;
    let pivot = v[mid];
    let (mut less, mut greater) = (Vec::new(), Vec::new());
    for (i, &x) in v.iter().enumerate() {
        if i == mid { continue; }
        *comparisons += 1;
        if x < pivot { less.push(x); } else { greater.push(x); }
    }
    let mut r = quicksort(&less, comparisons);
    r.push(pivot);
    r.extend(quicksort(&greater, comparisons));
    r
}

fn main() {
    let v: Vec<i32> = (0..2000).collect();
    let mut comparisons = 0u64;
    let sorted = quicksort(&v, &mut comparisons);
    println!("middle pivot O(n log n):    sorted {} items, {} comparisons", sorted.len(), comparisons);
}
