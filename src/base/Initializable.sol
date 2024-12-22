// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MASK_64_BITS} from "src/libraries/BitMasks.sol";

/// @title Initializable
/// @dev Modified from https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol

abstract contract Initializable {
	/// bytes32(uint256(keccak256("Initializing")) - 1)
	bytes32 private constant INITIALIZING_SLOT = 0x9536fd274b1da513899715f101ac7dd4165956a4323c575571d0d2c5d0ec45f8;

	/// bytes32(uint256(keccak256("LastRevision")) - 1)
	bytes32 private constant LAST_REVISION_SLOT = 0x2dcf4d2fa80344eb3d0178ea773deb29f1742cf017431f9ee326c624f742669b;

	// keccak256(bytes("Initialized(uint64)"))
	bytes32 private constant INITIALIZED_TOPIC = 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2;

	uint64 private constant MAX_UINT64 = (1 << 64) - 1;

	modifier initializer() {
		uint64 revision;
		bool isTopLevelCall;

		assembly ("memory-safe") {
			isTopLevelCall := iszero(tload(INITIALIZING_SLOT))
			revision := and(MASK_64_BITS, add(sload(LAST_REVISION_SLOT), 0x01))

			if isTopLevelCall {
				tstore(INITIALIZING_SLOT, 0x01)
			}

			if and(
				and(gt(revision, 0x02), iszero(isTopLevelCall)),
				not(
					or(and(eq(revision, 0x01), isTopLevelCall), and(eq(revision, 0x02), iszero(extcodesize(address()))))
				)
			) {
				mstore(0x00, 0xf92ee8a9) // InvalidInitialization()
				revert(0x1c, 0x04)
			}

			sstore(LAST_REVISION_SLOT, revision)
		}

		_;

		assembly ("memory-safe") {
			if isTopLevelCall {
				tstore(INITIALIZING_SLOT, 0x00)
				mstore(0x20, revision)
				log1(0x20, 0x20, INITIALIZED_TOPIC)
			}
		}
	}

	function disableInitializer() internal virtual {
		assembly ("memory-safe") {
			if tload(INITIALIZING_SLOT) {
				mstore(0x00, 0xf92ee8a9) // InvalidInitialization()
				revert(0x1c, 0x04)
			}

			if iszero(eq(sload(LAST_REVISION_SLOT), MAX_UINT64)) {
				sstore(LAST_REVISION_SLOT, MAX_UINT64)
				mstore(0x20, MAX_UINT64)
				log1(0x20, 0x20, INITIALIZED_TOPIC)
			}
		}
	}
}
