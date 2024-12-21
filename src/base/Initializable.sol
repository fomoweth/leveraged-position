// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Initializable
/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/src/utils/Initializable.sol

abstract contract Initializable {
	// bytes32(uint256(keccak256("initializable.state.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 private constant INITIALIZABLE_SLOT = 0xfac9fad39b8a9d9b1d25f884db7e62db964007ff991b61360cb73728afe15a00;

	// keccak256(bytes("Initialized(uint64)"))
	bytes32 private constant INITIALIZED_TOPIC = 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2;

	bytes4 private constant INVALID_INITIALIZATION_ERROR = 0xf92ee8a9; // InvalidInitialization()
	bytes4 private constant NOT_INITIALIZING_ERROR = 0xd7e6bcf8; // NotInitializing()

	modifier initializer() {
		bytes32 slot = INITIALIZABLE_SLOT;

		assembly ("memory-safe") {
			let state := sload(slot)
			sstore(slot, 3)

			if state {
				if iszero(lt(extcodesize(address()), eq(shr(1, state), 1))) {
					mstore(0x00, INVALID_INITIALIZATION_ERROR)
					revert(0x00, 0x04)
				}

				slot := shl(shl(255, state), slot)
			}
		}

		_;

		assembly ("memory-safe") {
			if slot {
				sstore(slot, 2)
				mstore(0x20, 1)
				log1(0x20, 0x20, INITIALIZED_TOPIC)
			}
		}
	}

	modifier reinitializer(uint64 version) {
		assembly ("memory-safe") {
			version := and(version, 0xffffffffffffffff)
			let state := sload(INITIALIZABLE_SLOT)

			if iszero(lt(and(state, 1), lt(shr(1, state), version))) {
				mstore(0x00, INVALID_INITIALIZATION_ERROR)
				revert(0x00, 0x04)
			}

			sstore(INITIALIZABLE_SLOT, or(1, shl(1, version)))
		}

		_;

		assembly ("memory-safe") {
			sstore(INITIALIZABLE_SLOT, shl(1, version))
			mstore(0x20, version)
			log1(0x20, 0x20, INITIALIZED_TOPIC)
		}
	}

	modifier onlyInitializing() {
		_checkInitializing();
		_;
	}

	function _disableInitializers() internal virtual {
		assembly ("memory-safe") {
			let state := sload(INITIALIZABLE_SLOT)

			if and(state, 1) {
				mstore(0x00, INVALID_INITIALIZATION_ERROR)
				revert(0x00, 0x04)
			}

			let maxUint64 := shr(192, INITIALIZABLE_SLOT)

			if iszero(eq(shr(1, state), maxUint64)) {
				sstore(INITIALIZABLE_SLOT, shl(1, maxUint64))
				mstore(0x20, maxUint64)
				log1(0x20, 0x20, INITIALIZED_TOPIC)
			}
		}
	}

	function _getInitializedVersion() internal view virtual returns (uint64 version) {
		assembly ("memory-safe") {
			version := shr(1, sload(INITIALIZABLE_SLOT))
		}
	}

	function _isInitializing() internal view virtual returns (bool status) {
		assembly ("memory-safe") {
			status := and(1, sload(INITIALIZABLE_SLOT))
		}
	}

	function _checkInitializing() internal view virtual {
		assembly ("memory-safe") {
			if iszero(and(1, sload(INITIALIZABLE_SLOT))) {
				mstore(0x00, NOT_INITIALIZING_ERROR)
				revert(0x00, 0x04)
			}
		}
	}
}
