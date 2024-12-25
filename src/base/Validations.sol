// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Errors} from "src/libraries/Errors.sol";

/// @title Validations

abstract contract Validations {
	function required(bool condition, bytes4 selector) internal pure {
		assembly ("memory-safe") {
			if iszero(condition) {
				mstore(0x00, selector)
				revert(0x00, 0x04)
			}
		}
	}

	function verifyAddress(address target) internal pure returns (address) {
		assembly ("memory-safe") {
			if iszero(target) {
				mstore(0x00, 0xd92e233d) // ZeroAddress()
				revert(0x1c, 0x04)
			}
		}

		return target;
	}

	function verifyBytes32(bytes32 target) internal pure returns (bytes32) {
		assembly ("memory-safe") {
			if iszero(target) {
				mstore(0x00, 0xdff66326) // ZeroBytes32()
				revert(0x1c, 0x04)
			}
		}

		return target;
	}

	function verifyContract(address target) internal view returns (address) {
		assembly ("memory-safe") {
			if iszero(extcodesize(target)) {
				mstore(0x00, 0x1858b10b) // EmptyCode()
				revert(0x1c, 0x04)
			}
		}

		return target;
	}
}
