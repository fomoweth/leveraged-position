// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

/// @title TypeConversion

library TypeConversion {
	function asBytes32(bool input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32Array(bool[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBool(bytes32 input) internal pure returns (bool output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBoolArray(bytes32[] memory input) internal pure returns (bool[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(address input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32Array(address[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asAddress(bytes32 input) internal pure returns (address output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asAddressArray(bytes32[] memory input) internal pure returns (address[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(Currency input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32Array(Currency[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asCurrency(bytes32 input) internal pure returns (Currency output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asCurrencyArray(bytes32[] memory input) internal pure returns (Currency[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes memory input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := mload(add(input, 0x20))
		}
	}

	function asBytes(bytes32 input) internal pure returns (bytes memory output) {
		assembly ("memory-safe") {
			output := mload(0x40)

			mstore(0x40, add(output, 0x40))
			mstore(output, 0x20)
			mstore(add(output, 0x20), input)
		}
	}

	function asBytes32(bytes1 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes1(bytes32 input) internal pure returns (bytes1 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes2 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes2(bytes32 input) internal pure returns (bytes2 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes3 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes3(bytes32 input) internal pure returns (bytes3 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes4 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes4(bytes32 input) internal pure returns (bytes4 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes5 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes5(bytes32 input) internal pure returns (bytes5 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes6 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes6(bytes32 input) internal pure returns (bytes6 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes7 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes7(bytes32 input) internal pure returns (bytes7 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes8 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes8(bytes32 input) internal pure returns (bytes8 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes9 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes9(bytes32 input) internal pure returns (bytes9 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes10 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes10(bytes32 input) internal pure returns (bytes10 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes11 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes11(bytes32 input) internal pure returns (bytes11 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes12 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes12(bytes32 input) internal pure returns (bytes12 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes13 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes13(bytes32 input) internal pure returns (bytes13 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes14 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes14(bytes32 input) internal pure returns (bytes14 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes15 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes15(bytes32 input) internal pure returns (bytes15 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes16 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes16(bytes32 input) internal pure returns (bytes16 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes17 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes17(bytes32 input) internal pure returns (bytes17 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes18 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes18(bytes32 input) internal pure returns (bytes18 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes19 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes19(bytes32 input) internal pure returns (bytes19 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes20 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes20(bytes32 input) internal pure returns (bytes20 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes21 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes21(bytes32 input) internal pure returns (bytes21 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes22 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes22(bytes32 input) internal pure returns (bytes22 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes23 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes23(bytes32 input) internal pure returns (bytes23 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes24 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes24(bytes32 input) internal pure returns (bytes24 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes25 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes25(bytes32 input) internal pure returns (bytes25 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes26 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes26(bytes32 input) internal pure returns (bytes26 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes27 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes27(bytes32 input) internal pure returns (bytes27 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes28 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes28(bytes32 input) internal pure returns (bytes28 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes29 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes29(bytes32 input) internal pure returns (bytes29 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes30 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes30(bytes32 input) internal pure returns (bytes30 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(bytes31 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes31(bytes32 input) internal pure returns (bytes31 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint8 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint8(bytes32 input) internal pure returns (uint8 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint16 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint16(bytes32 input) internal pure returns (uint16 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint24 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint24(bytes32 input) internal pure returns (uint24 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint32 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint32(bytes32 input) internal pure returns (uint32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint40 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint40(bytes32 input) internal pure returns (uint40 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint48 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint48(bytes32 input) internal pure returns (uint48 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint56 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint56(bytes32 input) internal pure returns (uint56 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint64 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint64(bytes32 input) internal pure returns (uint64 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint72 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint72(bytes32 input) internal pure returns (uint72 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint80 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint80(bytes32 input) internal pure returns (uint80 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint88 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint88(bytes32 input) internal pure returns (uint88 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint96 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint96(bytes32 input) internal pure returns (uint96 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint104 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint104(bytes32 input) internal pure returns (uint104 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint112 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint112(bytes32 input) internal pure returns (uint112 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint120 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint120(bytes32 input) internal pure returns (uint120 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint128 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint128(bytes32 input) internal pure returns (uint128 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint136 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint136(bytes32 input) internal pure returns (uint136 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint144 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint144(bytes32 input) internal pure returns (uint144 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint152 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint152(bytes32 input) internal pure returns (uint152 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint160 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint160(bytes32 input) internal pure returns (uint160 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint168 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint168(bytes32 input) internal pure returns (uint168 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint176 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint176(bytes32 input) internal pure returns (uint176 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint184 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint184(bytes32 input) internal pure returns (uint184 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint192 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint192(bytes32 input) internal pure returns (uint192 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint200 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint200(bytes32 input) internal pure returns (uint200 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint208 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint208(bytes32 input) internal pure returns (uint208 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint216 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint216(bytes32 input) internal pure returns (uint216 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint224 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint224(bytes32 input) internal pure returns (uint224 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint232 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint232(bytes32 input) internal pure returns (uint232 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint240 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint240(bytes32 input) internal pure returns (uint240 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint248 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint248(bytes32 input) internal pure returns (uint248 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(uint256 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32Array(uint256[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint256(bytes32 input) internal pure returns (uint256 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asUint256Array(bytes32[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int8 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt8(bytes32 input) internal pure returns (int8 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int16 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt16(bytes32 input) internal pure returns (int16 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int24 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt24(bytes32 input) internal pure returns (int24 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int32 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt32(bytes32 input) internal pure returns (int32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int40 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt40(bytes32 input) internal pure returns (int40 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int48 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt48(bytes32 input) internal pure returns (int48 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int56 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt56(bytes32 input) internal pure returns (int56 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int64 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt64(bytes32 input) internal pure returns (int64 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int72 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt72(bytes32 input) internal pure returns (int72 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int80 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt80(bytes32 input) internal pure returns (int80 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int88 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt88(bytes32 input) internal pure returns (int88 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int96 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt96(bytes32 input) internal pure returns (int96 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int104 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt104(bytes32 input) internal pure returns (int104 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int112 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt112(bytes32 input) internal pure returns (int112 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int120 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt120(bytes32 input) internal pure returns (int120 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int128 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt128(bytes32 input) internal pure returns (int128 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int136 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt136(bytes32 input) internal pure returns (int136 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int144 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt144(bytes32 input) internal pure returns (int144 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int152 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt152(bytes32 input) internal pure returns (int152 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int160 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt160(bytes32 input) internal pure returns (int160 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int168 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt168(bytes32 input) internal pure returns (int168 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int176 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt176(bytes32 input) internal pure returns (int176 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int184 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt184(bytes32 input) internal pure returns (int184 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int192 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt192(bytes32 input) internal pure returns (int192 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int200 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt200(bytes32 input) internal pure returns (int200 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int208 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt208(bytes32 input) internal pure returns (int208 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int216 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt216(bytes32 input) internal pure returns (int216 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int224 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt224(bytes32 input) internal pure returns (int224 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int232 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt232(bytes32 input) internal pure returns (int232 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int240 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt240(bytes32 input) internal pure returns (int240 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int248 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt248(bytes32 input) internal pure returns (int248 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32(int256 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asBytes32Array(int256[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt256(bytes32 input) internal pure returns (int256 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function asInt256Array(bytes32[] memory input) internal pure returns (int256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}
}
