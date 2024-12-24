// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title StorageSlot
/// @dev Provides functions to read and write primitive types to specific storage and transient-storage slots

library StorageSlot {
	function sstore(bytes32 slot, bytes32 value) internal {
		assembly ("memory-safe") {
			sstore(slot, value)
		}
	}

	function sclear(bytes32 slot) internal {
		assembly ("memory-safe") {
			sstore(slot, 0x00)
		}
	}

	function sload(bytes32 slot) internal view returns (bytes32 value) {
		assembly ("memory-safe") {
			value := sload(slot)
		}
	}

	function tstore(bytes32 slot, bytes32 value) internal {
		assembly ("memory-safe") {
			tstore(slot, value)
		}
	}

	function tclear(bytes32 slot) internal {
		assembly ("memory-safe") {
			tstore(slot, 0x00)
		}
	}

	function tload(bytes32 slot) internal view returns (bytes32 value) {
		assembly ("memory-safe") {
			value := tload(slot)
		}
	}

	function isEmpty(bytes32 slot) internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := iszero(tload(slot))
		}
	}

	function deriveMapping(bytes32 slot, bytes32 key) internal pure returns (bytes32 derivedSlot) {
		assembly ("memory-safe") {
			mstore(0x00, key)
			mstore(0x20, slot)
			derivedSlot := keccak256(0x00, 0x40)
		}
	}

	function deriveArray(bytes32 slot) internal pure returns (bytes32 derivedSlot) {
		assembly ("memory-safe") {
			mstore(0x00, slot)
			derivedSlot := keccak256(0x00, 0x20)
		}
	}

	function offset(bytes32 slot, uint256 index) internal pure returns (bytes32) {
		unchecked {
			return bytes32(uint256(slot) + index);
		}
	}
}
