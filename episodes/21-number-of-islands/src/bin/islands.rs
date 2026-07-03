// Count islands of '1' (land) in a grid of '1'/'0'. DFS "flood fill": when we
// find land, sink the whole connected island so we never count it twice.

fn num_islands(grid: &mut Vec<Vec<char>>) -> u32 {
    let (rows, cols) = (grid.len(), grid[0].len());
    let mut count = 0;
    for r in 0..rows {
        for c in 0..cols {
            if grid[r][c] == '1' {          // found new land
                count += 1;                 // it's a new island
                println!("island #{count} starts at ({r}, {c})");
                sink(grid, r as i32, c as i32);
            }
        }
    }
    count
}

fn sink(grid: &mut Vec<Vec<char>>, r: i32, c: i32) {
    let (rows, cols) = (grid.len() as i32, grid[0].len() as i32);
    if r < 0 || c < 0 || r >= rows || c >= cols || grid[r as usize][c as usize] != '1' {
        return;                             // off the grid, or water/visited -> stop
    }
    grid[r as usize][c as usize] = '0';     // sink this cell so we never revisit it
    sink(grid, r + 1, c);                   // down
    sink(grid, r - 1, c);                   // up
    sink(grid, r, c + 1);                   // right
    sink(grid, r, c - 1);                   // left
}

fn show(grid: &Vec<Vec<char>>) {
    for row in grid { println!("  {}", row.iter().collect::<String>()); }
}

fn main() {
    let mut grid = vec![
        vec!['1', '1', '0', '0', '0'],
        vec!['1', '1', '0', '0', '0'],
        vec!['0', '0', '1', '0', '0'],
        vec!['0', '0', '0', '1', '1'],
    ];
    println!("grid:");
    show(&grid);
    let n = num_islands(&mut grid);
    println!("number of islands = {n}");
}
