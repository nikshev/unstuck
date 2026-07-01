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

// IN-PLACE: walk the list once, flipping each node's next pointer to the
// previous node. O(1) extra space — we reuse the same nodes.
fn reverse(mut head: Link) -> Link {
    let mut prev: Link = None;
    while let Some(mut node) = head {
        head = node.next.take(); // detach the rest of the list
        node.next = prev;        // point this node backward
        prev = Some(node);       // prev advances to this node
    }
    prev
}

fn main() {
    let list = build(&[1, 2, 3, 4, 5]);
    println!("original: {}", show(&list));
    let rev = reverse(list);
    println!("reversed (in-place, O(1) space): {}", show(&rev));
}
