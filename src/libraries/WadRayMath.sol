// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title WadRayMath
/// @dev Implementation from https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/WadRayMath.sol

library WadRayMath {
	uint256 internal constant WAD = 1e18;
	uint256 internal constant HALF_WAD = 0.5e18;

	uint256 internal constant RAY = 1e27;
	uint256 internal constant HALF_RAY = 0.5e27;

	uint256 internal constant WAD_RAY_RATIO = 1e9;

	function wadMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(or(iszero(y), iszero(gt(x, div(sub(not(0), HALF_WAD), y))))) {
				invalid()
			}

			z := div(add(mul(x, y), HALF_WAD), WAD)
		}
	}

	function wadDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if or(iszero(y), iszero(iszero(gt(x, div(sub(not(0), div(y, 2)), WAD))))) {
				invalid()
			}

			z := div(add(mul(x, WAD), div(y, 2)), y)
		}
	}

	function rayMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(or(iszero(y), iszero(gt(x, div(sub(not(0), HALF_RAY), y))))) {
				invalid()
			}

			z := div(add(mul(x, y), HALF_RAY), RAY)
		}
	}

	function rayDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if or(iszero(y), iszero(iszero(gt(x, div(sub(not(0), div(y, 2)), RAY))))) {
				invalid()
			}

			z := div(add(mul(x, RAY), div(y, 2)), y)
		}
	}

	function rayToWad(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := div(x, WAD_RAY_RATIO)
			let remainder := mod(x, WAD_RAY_RATIO)

			if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
				z := add(z, 1)
			}
		}
	}

	function wadToRay(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := mul(x, WAD_RAY_RATIO)

			if iszero(eq(div(z, WAD_RAY_RATIO), x)) {
				invalid()
			}
		}
	}
}
