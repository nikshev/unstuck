// Quicksort with a BAD pivot: always the FIRST element.
// On already-sorted input this degrades to O(n^2).
fn quicksort(v: &[i32], comparisons: &mut u64) -> Vec<i32> {
    if v.len() <= 1 { return v.to_vec(); }
    let pivot = v[0];                       // <-- the trap
    let (mut less, mut greater) = (Vec::new(), Vec::new());
    for &x in &v[1..] {
        *comparisons += 1;
        if x < pivot { less.push(x); } else { greater.push(x); }
    }
    let mut r = quicksort(&less, comparisons);
    r.push(pivot);
    r.extend(quicksort(&greater, comparisons));
    r
}

fn main() {
    let v: Vec<i32> = (0..2000).collect(); // already sorted = worst case
    let mut comparisons = 0u64;
    let sorted = quicksort(&v, &mut comparisons);
    println!("first-element pivot O(n^2): sorted {} items, {} comparisons", sorted.len(), comparisons);
}
