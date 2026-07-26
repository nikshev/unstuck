// 3Sum — LeetCode 15. Find all unique triplets that sum to 0.
// Sort first, then fix one number and two-pointer the rest: O(n^2).
fn three_sum(mut nums: Vec<i32>) -> Vec<Vec<i32>> {
    nums.sort();                                   // enables two pointers + easy dedup
    let mut out = Vec::new();
    let n = nums.len();
    for i in 0..n {
        if i > 0 && nums[i] == nums[i - 1] { continue; }   // skip duplicate anchors
        let (mut lo, mut hi) = (i + 1, n.saturating_sub(1));
        while lo < hi {
            let sum = nums[i] + nums[lo] + nums[hi];
            if sum < 0 { lo += 1; }
            else if sum > 0 { hi -= 1; }
            else {
                out.push(vec![nums[i], nums[lo], nums[hi]]);
                lo += 1; hi -= 1;
                while lo < hi && nums[lo] == nums[lo - 1] { lo += 1; }  // skip dup lows
                while lo < hi && nums[hi] == nums[hi + 1] { hi -= 1; }  // skip dup highs
            }
        }
    }
    out
}

fn main() {
    println!("{:?}", three_sum(vec![-1, 0, 1, 2, -1, -4]));  // [[-1,-1,2],[-1,0,1]]
    println!("{:?}", three_sum(vec![0, 1, 1]));              // []
    println!("{:?}", three_sum(vec![0, 0, 0]));              // [[0,0,0]]
}
