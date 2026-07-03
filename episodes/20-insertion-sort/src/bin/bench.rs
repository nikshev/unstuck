use std::time::Instant;

fn insertion_sort(a: &mut [i32]) {
    for i in 1..a.len() {
        let key = a[i];
        let mut j = i;
        while j > 0 && a[j - 1] > key {
            a[j] = a[j - 1];
            j -= 1;
        }
        a[j] = key;
    }
}

fn main() {
    let n = 20_000;
    // WORST: reverse-sorted -> every element shifts all the way left -> O(n^2)
    let mut worst: Vec<i32> = (0..n).rev().collect();
    let t = Instant::now(); insertion_sort(&mut worst);
    println!("insertion, {}k reverse (worst): {:?}", n / 1000, t.elapsed());

    // BEST: already sorted -> inner while never runs -> O(n)
    let mut best: Vec<i32> = (0..n).collect();
    let t = Instant::now(); insertion_sort(&mut best);
    println!("insertion, {}k sorted   (best): {:?}", n / 1000, t.elapsed());

    // NEARLY sorted: only a few out of place -> almost O(n) (why it's used in real libs)
    let mut nearly: Vec<i32> = (0..n).collect();
    for k in (0..n as usize).step_by(500) { nearly.swap(k, (k + 1).min(n as usize - 1)); }
    let t = Instant::now(); insertion_sort(&mut nearly);
    println!("insertion, {}k nearly-sorted:   {:?}", n / 1000, t.elapsed());
}
