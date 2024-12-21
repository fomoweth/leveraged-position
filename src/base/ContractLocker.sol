// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MASK_160_BITS} from "src/libraries/BitMasks.sol";

/// @title ContractLocker
/// @notice Provides a reentrancy lock for external calls

abstract contract ContractLocker {
	/// bytes32(uint256(keccak256("Locker")) - 1)
	bytes32 private constant LOCKER_SLOT = 0x0e87e1788ebd9ed6a7e63c70a374cd3283e41cad601d21fbe27863899ed4a708;

	modifier lock() {
		_lock();
		_;
		_unlock();
	}

	function _lock() private {
		assembly ("memory-safe") {
			if iszero(iszero(tload(LOCKER_SLOT))) {
				mstore(0x00, 0x6f5ffb7e) // ContractLocked()
				revert(0x1c, 0x04)
			}

			tstore(LOCKER_SLOT, and(MASK_160_BITS, caller()))
		}
	}

	function _unlock() private {
		assembly ("memory-safe") {
			tstore(LOCKER_SLOT, 0x00)
		}
	}

	function lockedBy() internal view returns (address account) {
		assembly ("memory-safe") {
			account := tload(LOCKER_SLOT)
		}
	}
}
