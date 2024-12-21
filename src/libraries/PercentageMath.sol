// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title PercentageMath
/// @dev Implementation from https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol

library PercentageMath {
	uint256 internal constant BPS = 1e4;
	uint256 internal constant HALF_BPS = 0.5e4;

	function percentMul(uint256 x, uint256 percentage) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(or(iszero(percentage), iszero(gt(x, div(sub(not(0), HALF_BPS), percentage))))) {
				invalid()
			}

			z := div(add(mul(x, percentage), HALF_BPS), BPS)
		}
	}

	function percentDiv(uint256 x, uint256 percentage) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if or(iszero(percentage), iszero(iszero(gt(x, div(sub(not(0), div(percentage, 2)), BPS))))) {
				invalid()
			}

			z := div(add(mul(x, BPS), div(percentage, 2)), percentage)
		}
	}
}
