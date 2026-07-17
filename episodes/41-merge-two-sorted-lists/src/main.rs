// A singly-linked list on the heap: each node owns the rest of the list (Option<Box<..>>).
struct ListNode {
    val: i32,
    next: Option<Box<ListNode>>,
}

// Merge two SORTED lists into one sorted list. We take OWNERSHIP of both and reassemble them,
// no copies: pick the smaller head, then recurse on the rest.
fn merge(a: Option<Box<ListNode>>, b: Option<Box<ListNode>>) -> Option<Box<ListNode>> {
    match (a, b) {
        (None, rest) => rest,          // one side is empty -> the answer is the other side
        (rest, None) => rest,
        (Some(mut na), Some(mut nb)) => {
            if na.val <= nb.val {
                na.next = merge(na.next, Some(nb));   // keep a's head, merge what's left after it
                Some(na)
            } else {
                nb.next = merge(Some(na), nb.next);   // keep b's head
                Some(nb)
            }
        }
    }
}

// build a list from a slice, tail to head
fn from_vec(v: &[i32]) -> Option<Box<ListNode>> {
    let mut head = None;
    for &x in v.iter().rev() {
        head = Some(Box::new(ListNode { val: x, next: head }));
    }
    head
}

// print "1 -> 2 -> 3 -> None" by walking references (no ownership taken)
fn print_list(mut node: &Option<Box<ListNode>>) {
    while let Some(n) = node {
        print!("{} -> ", n.val);
        node = &n.next;
    }
    println!("None");
}

fn main() {
    let a = from_vec(&[1, 3, 5, 7]);
    let b = from_vec(&[2, 4, 6]);
    print!("list A:  "); print_list(&a);
    print!("list B:  "); print_list(&b);
    let merged = merge(a, b);           // a and b are consumed here
    print!("merged:  "); print_list(&merged);
}
