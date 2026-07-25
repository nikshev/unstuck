// Valid Parentheses (LeetCode 20), in Rust.
// A string of just ( ) [ ] { } is valid when every closer matches the
// MOST RECENT unmatched opener. "Most recent" is exactly a stack: push
// each opener; on a closer, pop and check it matches. O(n) time, O(n) space.

fn is_valid(s: &str) -> bool {
    let mut stack: Vec<char> = Vec::new();   // openers still waiting for a closer
    for c in s.chars() {
        match c {
            '(' | '[' | '{' => stack.push(c),                 // opener: remember it
            ')' => if stack.pop() != Some('(') { return false; },  // closer must match
            ']' => if stack.pop() != Some('[') { return false; },  // the LAST opener
            '}' => if stack.pop() != Some('{') { return false; },
            _ => {}                                            // ignore anything else
        }
    }
    stack.is_empty()   // valid only if nothing is left unmatched
}

fn main() {
    for s in ["()", "()[]{}", "(]", "([])", "([)]", "(("] {
        println!("{:8} -> {}", format!("{:?}", s), is_valid(s));
    }
}
