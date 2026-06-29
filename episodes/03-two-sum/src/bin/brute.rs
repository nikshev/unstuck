use std::time::Instant;

// O(n^2): check every possible pair
fn two_sum(nums: &[i32], target: i32) -> Option<(usize, usize)> {
    for i in 0..nums.len() {
        for j in (i + 1)..nums.len() {
            if nums[i] + nums[j] == target {
                return Some((i, j));
            }
        }
    }
    None
}

fn main() {
    // worst case: the answer is the very last pair
    let nums: Vec<i32> = (0..50_000).collect();
    let target = nums[nums.len() - 1] + nums[nums.len() - 2];

    let t = Instant::now();
    let ans = two_sum(&nums, target);
    println!("brute force  O(n^2): {:?}  in {:?}", ans, t.elapsed());
}
