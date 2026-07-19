// Product of Array Except Self (LeetCode 238), in Rust.
// output[i] = product of every element EXCEPT nums[i] — no division, O(n).
// The trick: (product of everything LEFT of i) x (product of everything RIGHT of i).

fn product_except_self(nums: Vec<i32>) -> Vec<i32> {
    let n = nums.len();
    let mut output = vec![1; n];      // the answer — also holds the prefix products

    // PASS 1 (left -> right): output[i] = product of everything BEFORE i
    let mut prefix = 1;
    for i in 0..n {
        output[i] = prefix;           // everything to the left, so far
        prefix *= nums[i];            // fold in nums[i] for the next slot
    }

    // PASS 2 (right -> left): multiply in the product of everything AFTER i
    let mut suffix = 1;
    for i in (0..n).rev() {
        output[i] *= suffix;          // left x right = product of all the others
        suffix *= nums[i];            // fold in nums[i] for the next slot
    }
    output
}

fn main() {
    let a = vec![1, 2, 3, 4];
    println!("{:?}  ->  {:?}", a, product_except_self(a.clone())); // [24, 12, 8, 6]
    // a single zero: only its own slot survives (product of the others = 9)
    let b = vec![-1, 1, 0, -3, 3];
    println!("{:?}  ->  {:?}", b, product_except_self(b.clone())); // [0, 0, 9, 0, 0]
    // two zeros: every slot has a zero among the others -> all zero
    let c = vec![0, 4, 0, 2];
    println!("{:?}  ->  {:?}", c, product_except_self(c.clone())); // [0, 0, 0, 0]
}
