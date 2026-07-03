// Watch insertion sort build a sorted region on the left, one card at a time.
fn main() {
    let mut a = vec![5, 2, 4, 6, 1, 3];
    println!("start:            {:?}", a);
    for i in 1..a.len() {
        let key = a[i];          // the "card" we're inserting
        let mut j = i;           // slide it left into the sorted part
        while j > 0 && a[j - 1] > key {
            a[j] = a[j - 1];     // shift a bigger element one slot right
            j -= 1;
        }
        a[j] = key;              // drop the card into its slot
        println!("insert {} -> {:?}", key, a);
    }
}
