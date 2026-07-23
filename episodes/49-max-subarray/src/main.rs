// Maximum Subarray (LeetCode 53), in Rust.
// Find the contiguous subarray with the largest sum.
// Kadane: the best run ENDING here is either x alone, or x added onto the best
// run ending just before it. Track that, and the best we have ever seen.
// O(n) time, O(1) space -- one pass, two integers.

fn max_sub_array(nums: Vec<i32>) -> i32 {
    let mut best = nums[0];        // best sum of any subarray so far
    let mut cur = nums[0];         // best sum of a subarray ENDING at this index
    for &x in &nums[1..] {
        cur = x.max(cur + x);      // extend the run, or start fresh at x
        best = best.max(cur);      // remember the best we have ever ended on
    }
    best
}

fn main() {
    let a = vec![-2, 1, -3, 4, -1, 2, 1, -5, 4];
    println!("{:?}  ->  {}", a, max_sub_array(a.clone()));   // 6  ([4,-1,2,1])
    let b = vec![1];
    println!("{:?}  ->  {}", b, max_sub_array(b.clone()));   // 1
    let c = vec![-3, -1, -2];
    println!("{:?}  ->  {}", c, max_sub_array(c.clone()));   // -1 (all negative)
}
