use std::collections::HashMap;

/// Return the k most frequent numbers. Bucket sort by frequency -> O(n).
fn top_k_frequent(nums: Vec<i32>, k: usize) -> Vec<i32> {
    // 1) count how often each number appears
    let mut freq: HashMap<i32, usize> = HashMap::new();
    for &n in &nums {
        *freq.entry(n).or_insert(0) += 1;
    }
    // 2) bucket the numbers by their frequency (index = count)
    let mut buckets: Vec<Vec<i32>> = vec![Vec::new(); nums.len() + 1];
    for (&num, &count) in &freq {
        buckets[count].push(num);
    }
    // 3) read buckets from the highest frequency down, take k
    let mut out = Vec::with_capacity(k);
    for count in (1..buckets.len()).rev() {
        for &num in &buckets[count] {
            out.push(num);
            if out.len() == k {
                return out;
            }
        }
    }
    out
}

fn main() {
    println!("{:?}", top_k_frequent(vec![1, 1, 1, 2, 2, 3], 2)); // [1, 2]
    println!("{:?}", top_k_frequent(vec![4, 4, 4, 5, 5, 6, 6, 6, 6], 2)); // [6, 4]
    println!("{:?}", top_k_frequent(vec![7], 1)); // [7]
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn example() {
        let mut got = top_k_frequent(vec![1, 1, 1, 2, 2, 3], 2);
        got.sort();
        assert_eq!(got, vec![1, 2]);
    }
    #[test]
    fn ties_pick_two() {
        let mut got = top_k_frequent(vec![4, 4, 4, 5, 5, 6, 6, 6, 6], 2);
        got.sort();
        assert_eq!(got, vec![4, 6]);
    }
    #[test]
    fn single_element() {
        assert_eq!(top_k_frequent(vec![7], 1), vec![7]);
    }
}
