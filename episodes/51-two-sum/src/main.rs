// Two Sum (LeetCode 1), in Rust.
// Return the indices of the two numbers that add up to target.
// The trick: one pass with a HashMap of value -> index. For each x, check if its
// COMPLEMENT (target - x) was already seen; if so, we have the pair. O(n) time, O(n) space.

use std::collections::HashMap;

fn two_sum(nums: Vec<i32>, target: i32) -> Vec<i32> {
    let mut seen: HashMap<i32, i32> = HashMap::new();   // value -> index
    for (i, &x) in nums.iter().enumerate() {
        if let Some(&j) = seen.get(&(target - x)) {     // complement already seen?
            return vec![j, i as i32];
        }
        seen.insert(x, i as i32);
    }
    vec![]
}

fn main() {
    println!("{:?}", two_sum(vec![2, 7, 11, 15], 9));   // [0, 1]  (2 + 7)
    println!("{:?}", two_sum(vec![3, 2, 4], 6));        // [1, 2]  (2 + 4)
    println!("{:?}", two_sum(vec![3, 3], 6));           // [0, 1]  (3 + 3)
}
