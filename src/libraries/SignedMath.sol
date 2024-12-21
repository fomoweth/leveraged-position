// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title SignedMath
/// @notice Provides functions to perform signed math operations

library SignedMath {
	function abs(int256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(sar(255, x), add(sar(255, x), x))
		}
	}

	function average(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := add(add(sar(1, x), sar(1, y)), and(1, and(x, y)))
		}
	}

	function ternary(bool condition, int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(y, mul(xor(x, y), iszero(iszero(condition))))
		}
	}

	function max(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(y, mul(xor(x, y), sgt(x, y)))
		}
	}

	function min(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(y, mul(xor(x, y), slt(x, y)))
		}
	}

	function add(int256 x, int256 y) internal pure returns (int256 z) {
		unchecked {
			z = x + y;
		}
	}

	function sub(int256 x, int256 y) internal pure returns (int256 z) {
		unchecked {
			z = x - y;
		}
	}

	function mul(int256 x, int256 y) internal pure returns (int256 z) {
		unchecked {
			z = x * y;
		}
	}

	function div(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := sdiv(x, y)
		}
	}

	function bound(int256 x, int256 lower, int256 upper) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, lower), sgt(lower, x)))
			z := xor(z, mul(xor(z, upper), slt(upper, z)))
		}
	}

	function dist(int256 x, int256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := add(xor(sub(0, sgt(x, y)), sub(y, x)), sgt(x, y))
		}
	}
}
