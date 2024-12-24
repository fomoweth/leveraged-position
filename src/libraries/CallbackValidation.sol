// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title CallbackValidation
/// @notice Provides validation for callbacks from Uniswap V3 Pools

library CallbackValidation {
	/// bytes32(uint256(keccak256("ExpectedCallback")) - 1)
	bytes32 private constant CALLBACK_SLOT = 0x386b0ec59649a15f46cd583b3e9ac5c37324bfaf11fe4aa462476971ac315d0b;

	function setUp(address expectedCaller, bytes4 expectedSig) internal {
		assembly ("memory-safe") {
			// verify that the slot is empty
			if iszero(iszero(tload(CALLBACK_SLOT))) {
				mstore(0x00, 0x55b9fb08) // SlotNotEmpty()
				revert(0x00, 0x04)
			}

			// verify that the expected caller is not zero
			if iszero(expectedCaller) {
				mstore(0x00, 0x48f5c3ed) // InvalidCaller()
				revert(0x00, 0x04)
			}

			// verify that the expected signature is not zero
			if iszero(expectedSig) {
				mstore(0x00, 0x8baa579f) // InvalidSignature()
				revert(0x00, 0x04)
			}

			// cache the expected caller and signature to the slot
			tstore(CALLBACK_SLOT, add(expectedSig, expectedCaller))
		}
	}

	function verify() internal {
		assembly ("memory-safe") {
			let cached := tload(CALLBACK_SLOT)

			// verify that the slot is not empty
			if iszero(cached) {
				mstore(0x00, 0xce174065) // SlotEmpty()
				revert(0x00, 0x04)
			}

			// verify that the msg.sender is equal to the cached caller
			if xor(caller(), shr(0x60, shl(0x60, cached))) {
				mstore(0x00, 0x48f5c3ed) // InvalidCaller()
				revert(0x00, 0x04)
			}

			// verify that the msg.sig is equal to the cached signature
			if xor(shl(0xe0, shr(0xe0, calldataload(0x00))), shl(0xe0, shr(0xe0, cached))) {
				mstore(0x00, 0x8baa579f) // InvalidSignature()
				revert(0x00, 0x04)
			}

			// clear the slot
			tstore(CALLBACK_SLOT, 0x00)
		}
	}
}
