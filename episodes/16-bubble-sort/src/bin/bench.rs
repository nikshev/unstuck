use std::time::Instant;

fn bubble_sort(a: &mut [i32]) {
    let n = a.len();
    for pass in 0..n {
        let mut swapped = false;
        for j in 0..n - 1 - pass {
            if a[j] > a[j + 1] { a.swap(j, j + 1); swapped = true; }
        }
        if !swapped { break; } // early exit: sorted input is O(n)
    }
}

fn main() {
    // WORST case: reverse-sorted
    let mut worst: Vec<i32> = (0..30_000).rev().collect();
    let t = Instant::now();
    bubble_sort(&mut worst);
    println!("bubble, 30k reverse-sorted (worst): {:?}", t.elapsed());

    // BEST case: already sorted — early exit makes it one pass, O(n)
    let mut best: Vec<i32> = (0..30_000).collect();
    let t = Instant::now();
    bubble_sort(&mut best);
    println!("bubble, 30k already sorted (best):  {:?}", t.elapsed());

    // what you should actually use in production:
    let mut std_sort: Vec<i32> = (0..30_000).rev().collect();
    let t = Instant::now();
    std_sort.sort_unstable();
    println!("std sort_unstable, same 30k:        {:?}", t.elapsed());
}
