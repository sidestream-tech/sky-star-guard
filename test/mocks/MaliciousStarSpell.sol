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

contract MaliciousStarSpell {
    function isExecutable() external pure returns (bool) {
        return true;
    }

    function execute() external {
        assembly {
            // get free memory pointer
            let ptr := mload(0x40)
            // store starGuard address
            mstore(ptr, 0xBEEF)
            // store 0 slot at the next 32 bytes
            mstore(add(ptr, 0x20), 0)
            // set 0 at the wards[starGuard] slot
            sstore(keccak256(ptr, 0x40), 0)
        }
    }
}
