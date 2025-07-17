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

interface SubProxyLike {
    function exec(address target, bytes memory args) external payable returns (bytes memory out);
    function wards(address) external view returns (uint256);
}

contract StarGuard {
    // ---------- Storage variables ----------

    /// @notice Addresses with owner access on this contract
    mapping(address usr => uint256 allowed) public wards;

    /// @notice Maximum delay in seconds between whitelisting and execution
    uint256 public expiration;

    /// @notice Whitelisted Star payload to be executed by `SubProxy`
    SpellData public spellData;

    // ---------- Structs ----------

    struct SpellData {
        address addr; // Spell address
        bytes32 tag;  // Spell codehash
        uint256 pat;  // Plotted at time
    }

    // ---------- Immutables ----------

    /// @notice Star admin contract (instance of `SubProxy`)
    SubProxyLike immutable public subProxy;

    // ---------- Events ----------

    /**
     * @notice `usr` was granted owner access
     * @param usr The user address
     */
    event Rely(address indexed usr);

    /**
     * @notice `usr` owner access was revoked
     * @param usr The user address
     */
    event Deny(address indexed usr);

    /**
     * @notice A contract parameter was updated
     * @param what The changed parameter name
     * @param data The new value of the parameter
     */
    event File(bytes32 indexed what, uint256 data);

    /**
     * @notice A spell has been whitelisted
     * @param addr The spell address
     * @param tag The spell codehash
     */
    event Plot(address indexed addr, bytes32 tag);

    /**
     * @notice A previously whitelisted spell has been dropped
     * @param addr The spell address
     */
    event Drop(address indexed addr);

    /**
     * @notice A previously whitelisted spell has been executed
     * @param addr The spell address
     */
    event Exec(address indexed addr);

    // ---------- Modifiers ----------

    modifier auth {
        require(wards[msg.sender] == 1, "StarGuard/not-authorized");
        _;
    }

    // ---------- Constructor ----------

    constructor(address subProxy_, uint256 expiration_) {
        subProxy = SubProxyLike(subProxy_);
        expiration = expiration_;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // ---------- Administration ----------

    /**
     * @notice Grants `usr` admin access to this contract
     * @param usr The user address
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract
     * @param usr The user address
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
     * @notice Common function to update meta-values
     * @param what Name of the variable
     * @param data New value of the ariable
     */
    function file(bytes32 what, uint256 data) external auth {
        if (what == "expiration") {
            expiration = data;
        } else revert("StarGuard/file-unrecognized-param");
        emit File(what, data);
    }

    // ---------- Operations ----------

    function plot(address addr_, bytes32 tag_) public auth {
        spellData.addr = addr_;
        spellData.tag  = tag_;
        spellData.pat  = block.timestamp;
        emit Plot(addr_, tag_);
    }

    function _drop() private {
        spellData.addr = address(0);
        spellData.tag  = bytes32(0);
        spellData.pat  = uint256(0);
    }

    function drop() public auth {
        emit Drop(spellData.addr);
        _drop();
    }

    function exec() public {
        SpellData memory spellDataCopy = spellData;
        _drop();

        require(spellDataCopy.tag != bytes32(0),                   "StarGuard/unplotted-spell");
        require(spellDataCopy.tag == spellDataCopy.addr.codehash,  "StarGuard/wrong-codehash");
        require(block.timestamp <= spellDataCopy.pat + expiration, "StarGuard/expired-spell");

        subProxy.exec(spellDataCopy.addr, abi.encodeWithSignature("execute()"));

        require(subProxy.wards(address(this)) == 1, "StarGuard/subProxy-owner-change");
        emit Exec(spellDataCopy.addr);
    }
}
