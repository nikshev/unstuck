// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Salmonella} from "../src/Salmonella.sol";
import {Bot} from "../src/Bot.sol";
import {SafeReceiver} from "../src/SafeReceiver.sol";

// Sepolia deploy. The deployer is the honeypot OWNER (its transfers move the full amount). A Bot
// contract stands in for a generalized front-runner (a non-owner -> its transfer moves only 1%).
contract SalmonellaSepolia is Script {
    function run() external {
        vm.startBroadcast();
        Salmonella salm = new Salmonella();
        Bot bot = new Bot();
        SafeReceiver safe = new SafeReceiver();
        salm.mint(msg.sender, 1_000e18);          // owner's stash (honest transfer)
        salm.mint(address(bot), 1_000e18);         // the bot's stash (the trap)
        vm.stopBroadcast();
        console2.log("SALM=%s", address(salm));
        console2.log("BOT=%s", address(bot));
        console2.log("SAFE=%s", address(safe));
        console2.log("OWNER=%s", msg.sender);
    }
}
