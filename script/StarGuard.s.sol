// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {StarGuard} from "../src/StarGuard.sol";

contract StarGuardScript is Script {
    StarGuard starGuard;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        starGuard = new StarGuard();

        vm.stopBroadcast();
    }
}
