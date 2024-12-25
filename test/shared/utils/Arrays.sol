// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {Bytes32Cast} from "./Bytes32Cast.sol";

library Arrays {
	using Bytes32Cast for *;

	function contains(bytes32[] memory input, bytes32 target) internal pure returns (uint256, bool) {
		uint256 length = input.length;
		uint256 offset;

		while (offset < length) {
			if (input[offset] == target) return (offset, true);
			++offset;
		}

		return (offset, false);
	}

	function contains(address[] memory input, address target) internal pure returns (uint256, bool) {
		return contains(input.castToBytes32Array(), target.castToBytes32());
	}

	function contains(Currency[] memory input, Currency target) internal pure returns (uint256, bool) {
		return contains(input.castToBytes32Array(), target.castToBytes32());
	}

	function contains(uint24[] memory input, uint24 target) internal pure returns (uint256, bool) {
		return contains(input.castToBytes32Array(), uint256(target).castToBytes32());
	}

	function contains(uint256[] memory input, uint256 target) internal pure returns (uint256, bool) {
		return contains(input.castToBytes32Array(), target.castToBytes32());
	}

	function filter(bytes32[] memory input, bytes32 target) internal pure returns (bytes32[] memory output) {
		uint256 length = input.length;
		uint256 count;

		for (uint256 i; i < length; ++i) {
			if (input[i] != target) {
				output[count] = input[i];
				++count;
			}
		}

		assembly ("memory-safe") {
			if xor(length, count) {
				mstore(output, count)
			}
		}
	}

	function filterZero(bytes32[] memory input) internal pure returns (bytes32[] memory output) {
		return filter(input, bytes32(0));
	}

	function filterZero(address[] memory input) internal pure returns (address[] memory output) {
		return filterZero(input.castToBytes32Array()).castToAddressArray();
	}

	function filterZero(Currency[] memory input) internal pure returns (Currency[] memory output) {
		return filterZero(input.castToBytes32Array()).castToCurrencyArray();
	}

	function filterZero(uint24[] memory input) internal pure returns (uint24[] memory output) {
		return filterZero(input.castToBytes32Array()).castToUint24Array();
	}

	function filterZero(uint256[] memory input) internal pure returns (uint256[] memory output) {
		return filterZero(input.castToBytes32Array()).castToUint256Array();
	}

	function reverse(bytes32[] memory input) internal pure returns (bytes32[] memory output) {
		uint256 length = input.length;
		output = new bytes32[](length);

		for (uint256 i; i < length; ++i) {
			output[i] = input[length - 1 - i];
		}
	}

	function reverse(address[] memory input) internal pure returns (address[] memory output) {
		return reverse(input.castToBytes32Array()).castToAddressArray();
	}

	function reverse(Currency[] memory input) internal pure returns (Currency[] memory output) {
		return reverse(input.castToBytes32Array()).castToCurrencyArray();
	}

	function reverse(uint24[] memory input) internal pure returns (uint24[] memory output) {
		return reverse(input.castToBytes32Array()).castToUint24Array();
	}

	function reverse(uint256[] memory input) internal pure returns (uint256[] memory output) {
		return reverse(input.castToBytes32Array()).castToUint256Array();
	}
}
