use std::time::Instant;

// DP (bottom-up): keep only the last two answers and walk up to n.
// Each step is computed exactly once. O(n) time, O(1) space.
fn ways(n: u64, steps: &mut u64) -> u64 {
    let (mut prev, mut curr) = (1u64, 1u64); // ways(0), ways(1)
    for _ in 2..=n {
        *steps += 1;
        let next = prev + curr;
        prev = curr;
        curr = next;
    }
    curr
}

fn main() {
    let n = 40;
    let mut steps = 0u64;
    let t = Instant::now();
    let w = ways(n, &mut steps);
    println!("bottom-up DP O(n):      ways({n}) = {w}");
    println!("  {} loop steps in {:?}", steps, t.elapsed());
}
