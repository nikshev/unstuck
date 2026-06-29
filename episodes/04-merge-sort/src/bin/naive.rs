use std::time::Instant;

// O(n^2): bubble the biggest value to the end on every pass
fn bubble_sort(a: &mut [i32]) {
    let n = a.len();
    for i in 0..n {
        let mut swapped = false;
        for j in 0..n - 1 - i {
            if a[j] > a[j + 1] {
                a.swap(j, j + 1);
                swapped = true;
            }
        }
        if !swapped { break; }
    }
}

fn main() {
    let mut v: Vec<i32> = (0..30_000).rev().collect(); // worst case
    let t = Instant::now();
    bubble_sort(&mut v);
    println!("bubble sort  O(n^2):     sorted {} items in {:?}", v.len(), t.elapsed());
}
