// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {Bytes32Cast} from "./Bytes32Cast.sol";

library Arrays {
	using Bytes32Cast for *;

	function filterZero(bytes32[] memory input) internal pure returns (bytes32[] memory) {
		uint256 length = input.length;
		uint256 count;

		for (uint256 i; i < length; ++i) {
			if (input[i] != bytes32(0)) ++count;
		}

		assembly ("memory-safe") {
			if xor(length, count) {
				mstore(input, count)
			}
		}

		return input;
	}

	function filterZero(address[] memory input) internal pure returns (address[] memory output) {
		return filterZero(input.castToBytes32Array()).castToAddressArray();
	}

	function filterZero(Currency[] memory input) internal pure returns (Currency[] memory output) {
		bytes32[] memory filtered = filterZero(input.castToBytes32Array());

		assembly ("memory-safe") {
			output := filtered
		}
	}

	function filterZero(uint24[] memory input) internal pure returns (uint24[] memory output) {
		bytes32[] memory filtered = filterZero(input.castToBytes32Array());

		assembly ("memory-safe") {
			output := filtered
		}
	}

	function filterZero(uint256[] memory input) internal pure returns (uint256[] memory output) {
		bytes32[] memory filtered = filterZero(input.castToBytes32Array());

		assembly ("memory-safe") {
			output := filtered
		}
	}

	function reverse(bytes32[] memory input) internal pure returns (bytes32[] memory output) {
		uint256 length = input.length;
		output = new bytes32[](length);

		unchecked {
			for (uint256 i; i < length; ++i) {
				output[i] = input[length - 1 - i];
			}
		}
	}

	function reverse(address[] memory input) internal pure returns (address[] memory output) {
		bytes32[] memory reversed = reverse(input.castToBytes32Array());

		assembly ("memory-safe") {
			output := reversed
		}
	}

	function reverse(Currency[] memory input) internal pure returns (Currency[] memory output) {
		bytes32[] memory reversed = reverse(input.castToBytes32Array());

		assembly ("memory-safe") {
			output := reversed
		}
	}

	function reverse(uint24[] memory input) internal pure returns (uint24[] memory output) {
		bytes32[] memory reversed = reverse(input.castToBytes32Array());

		assembly ("memory-safe") {
			output := reversed
		}
	}

	function reverse(uint256[] memory input) internal pure returns (uint256[] memory output) {
		bytes32[] memory reversed = reverse(input.castToBytes32Array());

		assembly ("memory-safe") {
			output := reversed
		}
	}
}
