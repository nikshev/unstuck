type Link = Option<Box<Node>>;
struct Node { val: i32, next: Link }

fn build(vals: &[i32]) -> Link {
    let mut head: Link = None;
    for &v in vals.iter().rev() {
        head = Some(Box::new(Node { val: v, next: head }));
    }
    head
}

fn show(head: &Link) -> String {
    let mut s = String::new();
    let mut cur = head;
    while let Some(n) = cur {
        if !s.is_empty() { s.push_str(" -> "); }
        s.push_str(&n.val.to_string());
        cur = &n.next;
    }
    s
}

// NAIVE: copy all values into a Vec, reverse the Vec, rebuild a NEW list.
// Works, but uses O(n) EXTRA memory for the Vec + a whole new list.
fn reverse(head: Link) -> Link {
    let mut vals = Vec::new();
    let mut cur = &head;
    while let Some(n) = cur { vals.push(n.val); cur = &n.next; }
    vals.reverse();
    build(&vals)
}

fn main() {
    let list = build(&[1, 2, 3, 4, 5]);
    println!("original: {}", show(&list));
    let rev = reverse(list);
    println!("reversed (naive, O(n) space): {}", show(&rev));
}
