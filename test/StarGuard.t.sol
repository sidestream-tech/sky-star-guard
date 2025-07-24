// SPDX-FileCopyrightText: © 2025 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.21;

import {Vm} from "forge-std/Vm.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {DssTest} from "dss-test/DssTest.sol";
import {SubProxy} from "endgame-toolkit/src/SubProxy.sol";
import {StarGuard} from "../src/StarGuard.sol";
import {StandardStarSpell} from "./mocks/StandardStarSpell.sol";
import {MaliciousStarSpell} from "./mocks/MaliciousStarSpell.sol";

contract StarGuardTest is DssTest {
    using stdStorage for StdStorage;

    StarGuard internal starGuard;
    address internal subProxy;
    address internal starSpell;

    address internal constant unauthedUser = address(0xB0B);

    function setUp() public {
        // Deploy required contracts
        subProxy = address(new SubProxy());
        starSpell = address(new StandardStarSpell());
        starGuard = new StarGuard(subProxy);

        // SubProxy is expected to authorize StarGuard
        SubProxy(subProxy).rely(address(starGuard));
    }

    function testConstructor() public {
        vm.recordLogs();

        // Deploy contract
        StarGuard newStarGuard = new StarGuard(subProxy);

        // Check emitted log
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics[0], keccak256("Rely(address)"));
        assertEq(address(uint160(uint256(entries[0].topics[1]))), address(this));

        // Check constructor effects
        assertEq(newStarGuard.wards(address(this)), 1);
        assertEq(address(newStarGuard.subProxy()), subProxy);
    }

    function testFile() public {
        checkFileUint(address(starGuard), "StarGuard", ["expiration"]);
    }

    function testAuth() public {
        checkAuth(address(starGuard), "StarGuard");
    }

    function testAuthModifiers() public {
        bytes4[] memory authedMethods = new bytes4[](2);
        authedMethods[0] = starGuard.plot.selector;
        authedMethods[1] = starGuard.drop.selector;

        vm.startPrank(unauthedUser);
        checkModifier(address(starGuard), "StarGuard/not-authorized", authedMethods);
        vm.stopPrank();
    }

    function testPlotAndDrop(address spell, bytes32 spellTag) public {
        vm.recordLogs();
        // Check initial state
        {
            (address addr, bytes32 tag, uint256 pat) = starGuard.spellData();
            assertEq(addr, address(0));
            assertEq(tag, bytes32(0));
            assertEq(pat, uint256(0));
        }

        // Plot
        starGuard.plot(spell, spellTag);
        {
            (address addr, bytes32 tag, uint256 pat) = starGuard.spellData();
            assertEq(addr, spell);
            assertEq(tag, spellTag);
            assertEq(pat, block.timestamp);
        }

        // Drop
        starGuard.drop();
        {
            (address addr, bytes32 tag, uint256 pat) = starGuard.spellData();
            assertEq(addr, address(0));
            assertEq(tag, bytes32(0));
            assertEq(pat, uint256(0));
        }

        // Check logs
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2);
        assertEq(entries[0].topics[0], keccak256("Plot(address,bytes32)"));
        assertEq(address(uint160(uint256(entries[0].topics[1]))), spell);
        assertEq(bytes32(entries[0].data), spellTag);
        assertEq(entries[1].topics[0], keccak256("Drop(address)"));
        assertEq(address(uint160(uint256(entries[1].topics[1]))), spell);
    }

    function testExec() public {
        starGuard.plot(starSpell, starSpell.codehash);
        vm.prank(unauthedUser);
        starGuard.exec();
    }

    function testPlotBeforeDeploy() public {
        // plot empty address
        address addressForTheNewSpell = address(0xC0FFEE);
        starGuard.plot(addressForTheNewSpell, starSpell.codehash);
        // try to execute empty address
        vm.prank(unauthedUser);
        vm.expectRevert();
        starGuard.exec();
        // deploy spell into the address
        vm.etch(addressForTheNewSpell, starSpell.code);
        // execute it
        vm.prank(unauthedUser);
        starGuard.exec();
    }

    function testExecUnplotted() public {
        vm.prank(unauthedUser);
        vm.expectRevert("StarGuard/unplotted-spell");
        starGuard.exec();
    }

    function testExecWrongCodehash() public {
        starGuard.plot(starSpell, bytes32("irrelevant codehash"));
        vm.prank(unauthedUser);
        vm.expectRevert("StarGuard/wrong-codehash");
        starGuard.exec();
    }

    function testExecExpiredSpell() public {
        starGuard.plot(starSpell, starSpell.codehash);
        vm.warp(block.timestamp + starGuard.expiration() + 1);
        vm.prank(unauthedUser);
        vm.expectRevert("StarGuard/expired-spell");
        starGuard.exec();
    }

    function testExecOwnerChange() public {
        // deploy StarGuard to a pre-defined address
        StarGuard starGuardAtKnownAddress = StarGuard(address(0xBEEF));
        // set code
        vm.etch(address(starGuardAtKnownAddress), address(starGuard).code);
        // authorize the deployer on the new StarGuard
        stdstore.target(address(starGuardAtKnownAddress)).sig("wards(address)").with_key(address(this)).checked_write(1);
        // SubProxy is expected to authorize StarGuard
        SubProxy(subProxy).rely(address(starGuardAtKnownAddress));
        // deploy malicious spell
        address maliciousStarSpell = address(new MaliciousStarSpell());
        // plot malicious spell
        starGuardAtKnownAddress.plot(maliciousStarSpell, maliciousStarSpell.codehash);
        // try to execute
        vm.prank(unauthedUser);
        vm.expectRevert("StarGuard/subProxy-owner-change");
        starGuardAtKnownAddress.exec();
    }
}
