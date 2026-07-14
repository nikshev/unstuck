/// A binary tree node: a value plus optional left/right children on the heap.
type Tree = Option<Box<Node>>;
struct Node { val: i32, left: Tree, right: Tree }

/// Invert (mirror) the tree: swap every node's two children, top to bottom. O(n).
fn invert(root: &mut Tree) {
    if let Some(node) = root {                            // empty spot? nothing to do
        std::mem::swap(&mut node.left, &mut node.right);  // swap THIS node's two children
        invert(&mut node.left);                           // recurse into the (new) left
        invert(&mut node.right);                          // recurse into the (new) right
    }
}

/// Read the tree level by level (breadth-first) so we can SEE the mirror.
fn level_order(root: &Tree) -> Vec<i32> {
    let mut out = Vec::new();
    let mut q: std::collections::VecDeque<&Node> = std::collections::VecDeque::new();
    if let Some(n) = root { q.push_back(n); }             // start with the root
    while let Some(n) = q.pop_front() {                   // pop, record, enqueue children
        out.push(n.val);
        if let Some(l) = &n.left  { q.push_back(l); }
        if let Some(r) = &n.right { q.push_back(r); }
    }
    out
}

fn leaf(v: i32) -> Tree { Some(Box::new(Node { val: v, left: None, right: None })) }
fn node(v: i32, l: Tree, r: Tree) -> Tree { Some(Box::new(Node { val: v, left: l, right: r })) }

fn main() {
    // sample:  4 -> (2,7) -> (1,3 | 6,9)
    let mut tree = node(4, node(2, leaf(1), leaf(3)), node(7, leaf(6), leaf(9)));
    println!("before: {:?}", level_order(&tree)); // [4, 2, 7, 1, 3, 6, 9]
    invert(&mut tree);
    println!("after:  {:?}", level_order(&tree)); // [4, 7, 2, 9, 6, 3, 1]
}
