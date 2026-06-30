// STACK: push opens, and on a close make sure the top is the MATCHING open.
fn is_valid(s: &str) -> bool {
    let mut stack: Vec<char> = Vec::new();
    for c in s.chars() {
        match c {
            '(' | '[' | '{' => stack.push(c),
            ')' => if stack.pop() != Some('(') { return false; },
            ']' => if stack.pop() != Some('[') { return false; },
            '}' => if stack.pop() != Some('{') { return false; },
            _ => {}
        }
    }
    stack.is_empty() // leftover opens => invalid
}

fn main() {
    for s in ["()", "([])", "([)]", "(]"] {
        println!("{:6} -> {}", s, is_valid(s));
    }
}
