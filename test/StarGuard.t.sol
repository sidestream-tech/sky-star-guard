// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StarGuard} from "../src/StarGuard.sol";

contract StarGuardTest is Test {
    StarGuard public starGuard;

    function setUp() public {
        starGuard = new StarGuard();
    }

    function testNoop() public view {
        assertNotEq(address(starGuard), address(0));
    }
}
