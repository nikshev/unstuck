# 21 — Number of Islands / DFS Flood Fill (Rust)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/Pqvb4RNYR4Y/maxresdefault.jpg)](https://youtu.be/Pqvb4RNYR4Y)

▶️ **Watch: https://youtu.be/Pqvb4RNYR4Y**


> Count groups of connected '1's in a grid. DFS "sink" each island so you never recount it.

📺 Video: _(soon)_

## The core ([`src/bin/islands.rs`](src/bin/islands.rs))
```rust
fn sink(grid: &mut Vec<Vec<char>>, r: i32, c: i32) {
    let (rows, cols) = (grid.len() as i32, grid[0].len() as i32);
    if r < 0 || c < 0 || r >= rows || c >= cols || grid[r as usize][c as usize] != '1' {
        return;                                 // base case FIRST: bounds + water
    }
    grid[r as usize][c as usize] = '0';         // mark visited by sinking it
    sink(grid, r+1, c); sink(grid, r-1, c); sink(grid, r, c+1); sink(grid, r, c-1);
}
```

## Run
```bash
cargo run --release --bin islands   # prints the grid, finds 3 islands
```
LeetCode #200. O(rows × cols). Same pattern as flood fill / max area of island / surrounded regions.
