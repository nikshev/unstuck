use std::collections::HashMap;
use std::time::Instant;

// OPTIMAL: every anagram shares the same SORTED KEY -> one HashMap lookup each.
fn group(words: &[String]) -> Vec<Vec<String>> {
    let mut map: HashMap<Vec<u8>, Vec<String>> = HashMap::new();
    for w in words {
        let mut key = w.as_bytes().to_vec();
        key.sort();                       // "eat","tea","ate" -> all "aet"
        map.entry(key).or_default().push(w.clone());
    }
    map.into_values().collect()
}

fn main() {
    let small = ["eat", "tea", "tan", "ate", "nat", "bat"].map(String::from);
    for g in group(&small) { println!("{:?}", g); }

    let words: Vec<String> = (0..2000).flat_map(|i| {
        let base = format!("w{i:04}abc");
        [base.clone(), base.chars().rev().collect(), format!("{}x", &base[..base.len()-1])]
    }).collect();
    let t = Instant::now();
    let n = group(&words).len();
    println!("sorted-key O(n·k log k): {} groups from {} words in {:?}", n, words.len(), t.elapsed());
}
