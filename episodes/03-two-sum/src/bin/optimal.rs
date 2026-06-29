use std::collections::HashMap;
use std::time::Instant;

// O(n): one pass, remember what we've seen, look up the complement
fn two_sum(nums: &[i32], target: i32) -> Option<(usize, usize)> {
    let mut seen: HashMap<i32, usize> = HashMap::new();
    for (i, &n) in nums.iter().enumerate() {
        if let Some(&j) = seen.get(&(target - n)) {
            return Some((j, i)); // complement was seen earlier
        }
        seen.insert(n, i);
    }
    None
}

fn main() {
    let nums: Vec<i32> = (0..50_000).collect();
    let target = nums[nums.len() - 1] + nums[nums.len() - 2];

    let t = Instant::now();
    let ans = two_sum(&nums, target);
    println!("hash map     O(n):   {:?}  in {:?}", ans, t.elapsed());
}
