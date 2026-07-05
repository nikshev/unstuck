// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ── Minimal token (approve / transferFrom) ───────────────────────────────
contract Token {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function approve(address s, uint256 a) external returns (bool) { allowance[msg.sender][s] = a; return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) {
        require(allowance[f][msg.sender] >= a, "allowance"); allowance[f][msg.sender] -= a;
        require(balanceOf[f] >= a, "balance"); balanceOf[f] -= a; balanceOf[t] += a; return true;
    }
}

// An honest user who APPROVED the router to spend their tokens (normal for a DEX).
contract VictimHolder {
    constructor(Token token, address router, uint256 amount) {
        token.mint(address(this), amount);
        token.approve(router, type(uint256).max);
    }
}

// ❌ VULNERABLE router — forwards ANY call the caller supplies, run AS THE ROUTER.
contract RouterVulnerable {
    function execute(address target, bytes calldata data) external returns (bytes memory) {
        (bool ok, bytes memory ret) = target.call(data);   // router is msg.sender
        require(ok, "call failed"); return ret;
    }
}

// ✅ FIXED router — only whitelisted targets. One extra line closes the drain.
contract RouterFixed {
    address public owner; mapping(address => bool) public allowed;
    constructor() { owner = msg.sender; }
    function setAllowed(address t, bool ok) external { require(msg.sender == owner, "not owner"); allowed[t] = ok; }
    function execute(address target, bytes calldata data) external returns (bytes memory) {
        require(allowed[target], "target not allowed");     // ← THE FIX
        (bool ok, bytes memory ret) = target.call(data);
        require(ok, "call failed"); return ret;
    }
}

// ▶ CLICK-TO-RUN demo of the OLD (vulnerable) path.
//   Deploy this (no arguments), then click: victimBalance -> attack -> victimBalance / attackerBalance.
contract Demo_OLD_Vulnerable {
    Token public token; RouterVulnerable public router; address public victim;
    constructor() {
        token = new Token(); router = new RouterVulnerable();
        victim = address(new VictimHolder(token, address(router), 1_000_000 ether));
    }
    function victimBalance()  external view returns (uint256) { return token.balanceOf(victim) / 1e18; }
    function attackerBalance() external view returns (uint256) { return token.balanceOf(address(this)) / 1e18; }
    function attack() external {
        // craft an ARBITRARY call: pull the victim's approved tokens to us
        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, victim, address(this), token.balanceOf(victim));
        router.execute(address(token), data);               // ← drains the victim
    }
}

// ▶ CLICK-TO-RUN demo of the NEW (fixed) path. Same attack() -> REVERTS.
contract Demo_NEW_Fixed {
    Token public token; RouterFixed public router; address public victim;
    constructor() {
        token = new Token(); router = new RouterFixed();
        victim = address(new VictimHolder(token, address(router), 1_000_000 ether));
    }
    function victimBalance() external view returns (uint256) { return token.balanceOf(victim) / 1e18; }
    function attack() external {
        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, victim, address(this), token.balanceOf(victim));
        router.execute(address(token), data);               // ← reverts: token not whitelisted
    }
}
