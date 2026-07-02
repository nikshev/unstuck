use std::time::Instant;

// NAIVE recursion: ways(n) = ways(n-1) + ways(n-2).
// Correct — but it recomputes the same subproblems over and over. O(2^n).
fn ways(n: u64, calls: &mut u64) -> u64 {
    *calls += 1;
    if n <= 1 { return 1; }
    ways(n - 1, calls) + ways(n - 2, calls)
}

fn main() {
    let n = 40;
    let mut calls = 0u64;
    let t = Instant::now();
    let w = ways(n, &mut calls);
    println!("naive recursion O(2^n): ways({n}) = {w}");
    println!("  {} function calls in {:?}", calls, t.elapsed());
}
