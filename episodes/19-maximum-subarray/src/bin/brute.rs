use std::time::Instant;

// NAIVE O(n^2): try EVERY subarray start i, extend end j, track the best sum.
fn max_subarray_brute(nums: &[i64]) -> i64 {
    let mut best = i64::MIN;
    for i in 0..nums.len() {
        let mut sum = 0;
        for j in i..nums.len() {   // every subarray nums[i..=j]
            sum += nums[j];
            best = best.max(sum);
        }
    }
    best
}

fn main() {
    let demo = [-2, 1, -3, 4, -1, 2, 1, -5, 4];
    println!("array: {:?}", demo);
    println!("brute-force max subarray sum = {}", max_subarray_brute(&demo));

    let big: Vec<i64> = (0..30_000).map(|i| ((i * 7 % 13) as i64) - 6).collect();
    let t = Instant::now();
    let r = max_subarray_brute(&big);
    println!("brute O(n^2) on {} elems: {} in {:?}", big.len(), r, t.elapsed());
}
