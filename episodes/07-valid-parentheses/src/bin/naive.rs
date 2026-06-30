// NAIVE: just count opens vs closes. Looks fine... but ignores ORDER.
fn is_valid(s: &str) -> bool {
    let mut balance = 0i32;
    for c in s.chars() {
        match c {
            '(' | '[' | '{' => balance += 1,
            ')' | ']' | '}' => balance -= 1,
            _ => {}
        }
        if balance < 0 { return false; }
    }
    balance == 0
}

fn main() {
    for s in ["()", "([])", "([)]", "(]"] {
        println!("{:6} -> {}", s, is_valid(s));
    }
    // BUG: "([)]" reports true, but the brackets are interleaved wrong.
}
