use std::collections::HashSet;

// A linked list where each node's `next` is an INDEX into the vector.
// In Rust, a Box-based list can't even form a cycle - single ownership
// forbids two nodes pointing at the same one - so we point with indices,
// which can point anywhere. Even backward. That's how we build a loop safely.
#[derive(Clone)]
struct Node {
    val: i32,
    next: Option<usize>,
}

// Naive: remember every node we've already visited. O(n) time, O(n) space.
fn has_cycle_set(nodes: &[Node], head: Option<usize>) -> bool {
    let mut seen = HashSet::new();
    let mut cur = head;
    while let Some(i) = cur {
        if !seen.insert(i) {
            return true; // insert returns false if it was already there -> cycle
        }
        cur = nodes[i].next;
    }
    false // walked off the end -> no cycle
}

// Floyd's tortoise & hare: two runners, one twice as fast. O(n) time, O(1) space.
fn has_cycle(nodes: &[Node], head: Option<usize>) -> bool {
    let mut slow = head;
    let mut fast = head;
    while let Some(f) = fast {
        // the hare moves TWO steps; if either step is off the end, no cycle
        fast = match nodes[f].next {
            Some(n) => nodes[n].next,
            None => return false,
        };
        // the tortoise moves ONE step
        slow = nodes[slow.unwrap()].next;
        // on a loop the hare laps the tortoise, so they land on the same node
        if slow == fast {
            return true;
        }
    }
    false
}

fn main() {
    // 3 -> 2 -> 0 -> 4 -> (back to 2)   a cycle
    let cyclic = vec![
        Node { val: 3, next: Some(1) },
        Node { val: 2, next: Some(2) },
        Node { val: 0, next: Some(3) },
        Node { val: 4, next: Some(1) }, // points back to index 1 -> loop
    ];
    // 1 -> 2 -> 3 -> None   no cycle
    let acyclic = vec![
        Node { val: 1, next: Some(1) },
        Node { val: 2, next: Some(2) },
        Node { val: 3, next: None },
    ];

    // the acyclic list, laid out (safe to walk - it ends):
    print!("list: ");
    let mut cur = Some(0);
    while let Some(i) = cur {
        print!("{} -> ", acyclic[i].val);
        cur = acyclic[i].next;
    }
    println!("None\n");

    println!("cyclic list  ->  HashSet: {:<5}  Floyd: {}",
             has_cycle_set(&cyclic, Some(0)), has_cycle(&cyclic, Some(0)));
    println!("acyclic list ->  HashSet: {:<5}  Floyd: {}",
             has_cycle_set(&acyclic, Some(0)), has_cycle(&acyclic, Some(0)));
    println!("\nFloyd's uses O(1) memory; the HashSet uses O(n). Same answer, no extra space.");
}
