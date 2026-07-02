use std::time::Instant;

// NAIVE: compare every word against every group's representative. O(n² · k).
fn sorted(w: &str) -> Vec<u8> { let mut b = w.as_bytes().to_vec(); b.sort(); b }

fn group(words: &[String]) -> Vec<Vec<String>> {
    let mut groups: Vec<Vec<String>> = Vec::new();
    for w in words {
        let mut placed = false;
        for g in groups.iter_mut() {
            if sorted(&g[0]) == sorted(w) {   // re-sorts every time we compare
                g.push(w.clone());
                placed = true;
                break;
            }
        }
        if !placed { groups.push(vec![w.clone()]); }
    }
    groups
}

fn main() {
    let small = ["eat", "tea", "tan", "ate", "nat", "bat"].map(String::from);
    for g in group(&small) { println!("{:?}", g); }

    // benchmark: 6000 words in 2000 anagram families
    let words: Vec<String> = (0..2000).flat_map(|i| {
        let base = format!("w{i:04}abc");
        [base.clone(), base.chars().rev().collect(), format!("{}x", &base[..base.len()-1])]
    }).collect();
    let t = Instant::now();
    let n = group(&words).len();
    println!("pairwise O(n^2): {} groups from {} words in {:?}", n, words.len(), t.elapsed());
}
