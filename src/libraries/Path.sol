// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

/// @title Path
/// @dev Modified from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/Path.sol

library Path {
	uint256 private constant ADDR_SIZE = 20;
	uint256 private constant FEE_SIZE = 3;
	uint256 private constant NEXT_OFFSET = 23; // ADDR_SIZE + FEE_SIZE
	uint256 private constant POP_OFFSET = 43; // NEXT_OFFSET + ADDR_SIZE
	uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = 66; // POP_OFFSET + NEXT_OFFSET

	function hasMultiplePools(bytes calldata path) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			flag := iszero(lt(path.length, MULTIPLE_POOLS_MIN_LENGTH))
		}
	}

	function numPools(bytes calldata path) internal pure returns (uint256 n) {
		assembly ("memory-safe") {
			n := div(sub(path.length, ADDR_SIZE), NEXT_OFFSET)
		}
	}

	function decodeFirstPool(
		bytes calldata path
	) internal pure returns (Currency currencyIn, Currency currencyOut, uint24 fee) {
		assembly ("memory-safe") {
			let firstWord := calldataload(path.offset)
			currencyIn := shr(0x60, firstWord)
			fee := and(shr(0x48, firstWord), 0xffffff)
			currencyOut := shr(0x60, calldataload(add(path.offset, NEXT_OFFSET)))
		}
	}

	function decodeFirstCurrency(bytes calldata path) internal pure returns (Currency currencyA) {
		assembly ("memory-safe") {
			currencyA := shr(0x60, calldataload(path.offset))
		}
	}

	function getFirstPool(bytes calldata path) internal pure returns (bytes calldata res) {
		assembly ("memory-safe") {
			res.offset := path.offset
			res.length := POP_OFFSET
		}
	}

	function skipCurrency(bytes calldata path) internal pure returns (bytes calldata res) {
		assembly ("memory-safe") {
			res.offset := add(path.offset, NEXT_OFFSET)
			res.length := sub(path.length, NEXT_OFFSET)
		}
	}

	function verify(bytes calldata path, Currency currencyFirst, Currency currencyLast) internal pure {
		assembly ("memory-safe") {
			if or(lt(path.length, POP_OFFSET), iszero(iszero(mod(sub(path.length, ADDR_SIZE), NEXT_OFFSET)))) {
				mstore(0x00, 0xcd608bfe) // InvalidPathLength()
				revert(0x1c, 0x04)
			}

			if xor(shr(0x60, calldataload(path.offset)), currencyFirst) {
				mstore(0x00, 0xa09ccde9) // InvalidCurrencyFirst()
				revert(0x1c, 0x04)
			}

			if xor(shr(0x60, calldataload(add(path.offset, sub(path.length, ADDR_SIZE)))), currencyLast) {
				mstore(0x00, 0x53da3a83) // InvalidCurrencyLast()
				revert(0x1c, 0x04)
			}
		}
	}
}
