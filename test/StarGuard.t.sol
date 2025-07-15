// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { DssTest } from "dss-test/DssTest.sol";
import { Vm } from "forge-std/Vm.sol";
import { StarGuard } from "../src/StarGuard.sol";

contract StarGuardTest is DssTest {
    StarGuard public starGuard;

    uint256 internal constant expiration = 24 hours;
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant subProxy = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    function setUp() public {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(MAINNET_RPC_URL);

        starGuard = new StarGuard(subProxy, expiration);
    }

    function testConstructor() public {
        vm.recordLogs();
        
        // Deploy contract
        StarGuard newStarGuard = new StarGuard(subProxy, expiration);
        
        // Check emitted log
        Vm.Log[] memory entries = vm.getRecordedLogs(); 
        assertEq(entries.length, 1);
        assertEq(entries[0].topics[0], keccak256("Rely(address)"));
        assertEq(address(uint160(uint256(entries[0].topics[1]))), address(this));

        // Check constructor effects
        assertEq(newStarGuard.wards(address(this)), 1);
        assertEq(address(newStarGuard.subProxy()), subProxy);
        assertEq(newStarGuard.expiration(), expiration);
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

        vm.startPrank(address(0xB0B));
        checkModifier(address(starGuard), "StarGuard/not-authorized", authedMethods);
        vm.stopPrank();
    }

    function testPlotAndDrop(address spell, bytes32 spellTag) public {
        vm.recordLogs();
        // Check initial state
        {
            (address addr, bytes32 tag, uint256 pat) = starGuard.spellData();
            assertEq(addr, address(0));
            assertEq(tag,  bytes32(0));
            assertEq(pat,  uint256(0));
        }

        // Plot
        starGuard.plot(spell, spellTag);
        {
            (address addr, bytes32 tag, uint256 pat) = starGuard.spellData();
            assertEq(addr, spell);
            assertEq(tag,  spellTag);
            assertEq(pat,  block.timestamp);
        }

        // Drop
        starGuard.drop();
        {
            (address addr, bytes32 tag, uint256 pat) = starGuard.spellData();
            assertEq(addr, address(0));
            assertEq(tag,  bytes32(0));
            assertEq(pat,  uint256(0));
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
}
