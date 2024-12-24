// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Math} from "src/libraries/Math.sol";

library LiquidityAmounts {
	uint256 internal constant Q96 = 0x1000000000000000000000000;
	uint256 internal constant RESOLUTION = 96;

	function toUint128(uint256 x) private pure returns (uint128 y) {
		require((y = uint128(x)) == x);
	}

	function getLiquidityForAmount0(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount0
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
		uint256 intermediate = Math.mulDiv(sqrtRatioAX96, sqrtRatioBX96, Q96);
		unchecked {
			return toUint128(Math.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
		}
	}

	function getLiquidityForAmount1(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount1
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
		unchecked {
			return toUint128(Math.mulDiv(amount1, Q96, sqrtRatioBX96 - sqrtRatioAX96));
		}
	}

	function getLiquidityForAmounts(
		uint160 sqrtRatioX96,
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount0,
		uint256 amount1
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		if (sqrtRatioX96 <= sqrtRatioAX96) {
			liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
		} else if (sqrtRatioX96 < sqrtRatioBX96) {
			uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
			uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

			liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
		} else {
			liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
		}
	}

	function getAmount0ForLiquidity(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount0) {
		unchecked {
			if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

			return
				Math.mulDiv(uint256(liquidity) << RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96) /
				sqrtRatioAX96;
		}
	}

	function getAmount1ForLiquidity(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount1) {
		if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		unchecked {
			return Math.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, Q96);
		}
	}

	function getAmountsForLiquidity(
		uint160 sqrtRatioX96,
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount0, uint256 amount1) {
		if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		if (sqrtRatioX96 <= sqrtRatioAX96) {
			amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
		} else if (sqrtRatioX96 < sqrtRatioBX96) {
			amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
			amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
		} else {
			amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
		}
	}
}
