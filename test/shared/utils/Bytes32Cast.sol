// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

library Bytes32Cast {
	function castToBytes4(bytes32 input) internal pure returns (bytes4 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes4Array(bytes32[] memory input) internal pure returns (bytes4[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes4 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32Array(bytes4[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToAddress(bytes32 input) internal pure returns (address output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToAddressArray(bytes32[] memory input) internal pure returns (address[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(address input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32Array(address[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToCurrency(bytes32 input) internal pure returns (Currency output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToCurrencyArray(bytes32[] memory input) internal pure returns (Currency[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(Currency input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32Array(Currency[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToUint24(bytes32 input) internal pure returns (uint24 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToUint24Array(bytes32[] memory input) internal pure returns (uint24[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(uint24 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32Array(uint24[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToUint128(bytes32 input) internal pure returns (uint128 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToUint128Array(bytes32[] memory input) internal pure returns (uint128[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(uint128 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32Array(uint128[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToUint256(bytes32 input) internal pure returns (uint256 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToUint256Array(bytes32[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(uint256 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32Array(uint256[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToInt128(bytes32 input) internal pure returns (int128 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToInt128Array(bytes32[] memory input) internal pure returns (int128[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(int128 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32Array(int128[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToInt256(bytes32 input) internal pure returns (int256 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToInt256Array(bytes32[] memory input) internal pure returns (int256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(int256 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32Array(int256[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}
}
