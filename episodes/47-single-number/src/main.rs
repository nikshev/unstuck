// Single Number (LeetCode 136), in Rust.
// Every value appears exactly TWICE except one. Return the value that appears once.
// The trick: XOR. a ^ a == 0 (a pair cancels itself out) and a ^ 0 == a.
// So XOR the whole array: every matched pair wipes to 0, and only the lonely
// number is left standing. O(n) time, O(1) space -- no HashSet, no sorting.

fn single_number(nums: Vec<i32>) -> i32 {
    let mut acc = 0;              // 0 is the XOR identity: 0 ^ x == x
    for x in nums {
        acc ^= x;                 // pairs cancel to 0; the unique value survives
    }
    acc
}

fn main() {
    let a = vec![2, 2, 1];
    println!("{:?}  ->  {}", a, single_number(a.clone()));       // 1
    let b = vec![4, 1, 2, 1, 2];
    println!("{:?}  ->  {}", b, single_number(b.clone()));       // 4
    let c = vec![7];
    println!("{:?}  ->  {}", c, single_number(c.clone()));       // 7  (0 ^ 7 = 7)
}
