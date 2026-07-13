/// Find `target` in a rotated sorted array; return its index or -1. O(log n).
fn search(nums: Vec<i32>, target: i32) -> i32 {
    // 1) two pointers over the whole array
    let (mut lo, mut hi) = (0i32, nums.len() as i32 - 1); // scan the whole range
    // 2) each step: decide WHICH half is sorted
    // 3) is target in the sorted half? narrow accordingly
    while lo <= hi {
        let mid = (lo + hi) / 2;                        // middle index
        if nums[mid as usize] == target {               // found it right away?
            return mid;
        }
        if nums[lo as usize] <= nums[mid as usize] {     // LEFT half is sorted
            if nums[lo as usize] <= target && target < nums[mid as usize] {
                hi = mid - 1;                           // target sits in the sorted left
            } else {
                lo = mid + 1;                           // otherwise search the right
            }
        } else {                                         // RIGHT half is sorted
            if nums[mid as usize] < target && target <= nums[hi as usize] {
                lo = mid + 1;                           // target sits in the sorted right
            } else {
                hi = mid - 1;                           // otherwise search the left
            }
        }
    }
    -1
}

fn main() {
    println!("{}", search(vec![4, 5, 6, 7, 0, 1, 2], 0)); // 4
    println!("{}", search(vec![4, 5, 6, 7, 0, 1, 2], 3)); // -1
    println!("{}", search(vec![1], 0));                   // -1
}
