// Watch bubble sort work: print the array after every pass.
// Big values "bubble" to the end; early-exit stops when a pass makes no swaps.
fn main() {
    let mut a = vec![5, 1, 4, 2, 8];
    println!("start:        {:?}", a);
    let n = a.len();
    for pass in 0..n {
        let mut swapped = false;
        for j in 0..n - 1 - pass {
            if a[j] > a[j + 1] {
                a.swap(j, j + 1);
                swapped = true;
            }
        }
        println!("after pass {}: {:?}{}", pass + 1, a,
                 if swapped { "" } else { "   <- no swaps, DONE" });
        if !swapped { break; }
    }
}
