// Coin Change (LeetCode 322): the fewest coins that add up to `amount`.
// Naive recursion: try every coin as the last one, recurse on the rest. The same amounts get
// recomputed again and again -> exponential.
fn min_coins_naive(coins: &[u32], amount: u32) -> i64 {
    if amount == 0 { return 0; }
    let mut best = i64::MAX;
    for &c in coins {
        if c <= amount {
            let sub = min_coins_naive(coins, amount - c);
            if sub != i64::MAX { best = best.min(sub + 1); }
        }
    }
    best
}
// Bottom-up DP: dp[a] = fewest coins to make `a`. Solve each amount ONCE, smallest first.
fn min_coins(coins: &[u32], amount: u32) -> i64 {
    let big = i64::MAX;
    let mut dp = vec![big; (amount + 1) as usize];
    dp[0] = 0;                                     // zero coins make zero
    for a in 1..=amount as usize {                 // build up every amount, 1..=amount
        for &c in coins {                          // try each coin as the LAST coin
            let c = c as usize;
            if c <= a && dp[a - c] != big {
                dp[a] = dp[a].min(dp[a - c] + 1);  // one more coin than the remainder
            }
        }
    }
    dp[amount as usize]                            // the answer (big => impossible)
}

fn main() {
    let coins = [1u32, 3, 4];
    for amount in [6u32, 2, 11, 0] {
        println!("amount {:>2}: naive {:>3}  dp {:>3}", amount,
                 min_coins_naive(&coins, amount), min_coins(&coins, amount));
    }
}

