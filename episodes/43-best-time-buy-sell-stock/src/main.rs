// Best Time to Buy and Sell Stock (LeetCode 121), in Rust.
// One pass: remember the cheapest price seen so far, and the best profit if we sold today.

fn max_profit(prices: &[i32]) -> i32 {
    let mut min_price = i32::MAX; // cheapest buy price seen so far
    let mut best = 0;             // best profit found so far
    for &price in prices {
        if price < min_price {
            min_price = price;               // a new cheapest day to have bought
        } else if price - min_price > best {
            best = price - min_price;        // selling today beats our best
        }
    }
    best
}

fn main() {
    let prices = [7, 1, 5, 3, 6, 4];
    println!("prices:      {:?}", prices);
    println!("max profit:  {}", max_profit(&prices)); // buy at 1, sell at 6 -> 5
    // edge cases
    println!("descending:  {}", max_profit(&[7, 6, 4, 3, 1])); // never profitable -> 0
    println!("empty:       {}", max_profit(&[]));               // -> 0
}
