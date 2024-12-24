// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Vm} from "forge-std/Vm.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";

import {IQuoter} from "src/interfaces/external/uniswap/v3/IQuoter.sol";
import {IUniswapV3Pool} from "src/interfaces/external/uniswap/v3/IUniswapV3Pool.sol";
import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Currency} from "src/types/Currency.sol";

import {Configured} from "config/Configured.sol";

import {Common} from "test/shared/extensions/Common.sol";
import {Arrays} from "./Arrays.sol";
import {LiquidityAmounts} from "./LiquidityAmounts.sol";
import {TickMath} from "./TickMath.sol";

contract Routes is Configured, Common {
	using Arrays for Currency[];
	using Arrays for uint24[];
	using CurrencyNamer for Currency;

	Vm private constant vm = Vm(VM);

	uint256 internal constant ADDR_SIZE = 20;
	uint256 internal constant FEE_SIZE = 3;
	uint256 internal constant NEXT_OFFSET = 23;
	uint256 internal constant POP_OFFSET = 43;
	uint256 internal constant MULTIPLE_POOLS_MIN_LENGTH = 66;

	uint24 internal constant FEE_LOWEST = 100;
	uint24 internal constant FEE_LOW = 500;
	uint24 internal constant FEE_MEDIUM = 3000;
	uint24 internal constant FEE_HIGH = 10000;

	bytes4 internal constant QUOTE_EXACT_INPUT_SELECTOR = 0xcdca1753;
	bytes4 internal constant QUOTE_EXACT_INPUT_SINGLE_SELECTOR = 0xc6a5026a;
	bytes4 internal constant QUOTE_EXACT_OUTPUT_SELECTOR = 0x2f80bb1d;
	bytes4 internal constant QUOTE_EXACT_OUTPUT_SINGLE_SELECTOR = 0xbd21704a;

	constructor() {
		configure();
	}

	function findRouteForExactIn(
		Currency currencyIn,
		Currency currencyOut,
		uint256 amountIn
	) public returns (bytes memory path, uint256 amountOut) {
		vm.assume(amountIn != 0);

		Currency[] memory currencies = new Currency[](3);
		currencies[0] = currencyIn;
		currencies[2] = currencyOut;

		uint24[] memory fees = new uint24[](2);

		for (uint256 i; i < intermediateCurrencies.length; ++i) {
			Currency currencyIntermediate = intermediateCurrencies[i];
			if (currencyIn == currencyIntermediate || currencyOut == currencyIntermediate) continue;

			(IUniswapV3Pool poolIntermediate0, uint24 fee0, ) = getPoolWithMostLiquidity(
				currencyIn,
				currencyIntermediate
			);
			if (!isContract(address(poolIntermediate0))) continue;

			(IUniswapV3Pool poolIntermediate1, uint24 fee1, ) = getPoolWithMostLiquidity(
				currencyIntermediate,
				currencyOut
			);
			if (!isContract(address(poolIntermediate1))) continue;

			try
				UNISWAP_V3_QUOTER.quoteExactInput(
					encodePath(getCurrencies(currencyIn, currencyIntermediate, currencyOut), getPoolFees(fee0, fee1)),
					amountIn
				)
			returns (uint256 amountOutQuote, uint160[] memory, uint32[] memory, uint256) {
				if (amountOutQuote > amountOut) {
					currencies[1] = currencyIntermediate;
					fees[0] = fee0;
					fees[1] = fee1;
					amountOut = amountOutQuote;
				}
			} catch {}
		}

		(IUniswapV3Pool poolDirect, uint24 feeDirect, uint256 quoteDirect) = findBestPoolForExactIn(
			currencyIn,
			currencyOut,
			amountIn
		);

		if (quoteDirect > amountOut) {
			path = abi.encodePacked(currencyIn, feeDirect, currencyOut);
			amountOut = quoteDirect;

			labelPool(poolDirect);
		} else if (amountOut != 0) {
			path = encodePath(currencies, fees);

			labelPool(getPool(currencies[0], currencies[1], fees[0]));
			labelPool(getPool(currencies[1], currencies[2], fees[1]));
		}
	}

	function findRouteForExactOut(
		Currency currencyIn,
		Currency currencyOut,
		uint256 amountOut
	) public returns (bytes memory path, uint256 amountIn) {
		vm.assume(amountOut != 0);

		amountIn = MAX_UINT256;

		Currency[] memory currencies = new Currency[](3);
		currencies[0] = currencyOut;
		currencies[2] = currencyIn;

		uint24[] memory fees = new uint24[](2);

		for (uint256 i; i < intermediateCurrencies.length; ++i) {
			Currency currencyIntermediate = intermediateCurrencies[i];
			if (currencyOut == currencyIntermediate || currencyIn == currencyIntermediate) continue;

			(IUniswapV3Pool pool0, uint24 fee0, ) = getPoolWithMostLiquidity(currencyOut, currencyIntermediate);
			if (!isContract(address(pool0))) continue;

			(IUniswapV3Pool pool1, uint24 fee1, ) = getPoolWithMostLiquidity(currencyIntermediate, currencyIn);
			if (!isContract(address(pool1))) continue;

			try
				UNISWAP_V3_QUOTER.quoteExactOutput(
					encodePath(getCurrencies(currencyOut, currencyIntermediate, currencyIn), getPoolFees(fee0, fee1)),
					amountOut
				)
			returns (uint256 amountInQuote, uint160[] memory, uint32[] memory, uint256) {
				if (amountInQuote != 0 && amountInQuote < amountIn) {
					currencies[1] = currencyIntermediate;
					fees[0] = fee0;
					fees[1] = fee1;
					amountIn = amountInQuote;
				}
			} catch {}
		}

		(IUniswapV3Pool poolDirect, uint24 feeDirect, uint256 quoteDirect) = findBestPoolForExactOut(
			currencyIn,
			currencyOut,
			amountOut
		);

		if (quoteDirect != 0 && quoteDirect < amountIn) {
			path = abi.encodePacked(currencyOut, feeDirect, currencyIn);
			amountIn = quoteDirect;

			labelPool(poolDirect);
		} else if (amountIn != MAX_UINT256) {
			path = encodePath(currencies, fees);

			labelPool(getPool(currencies[0], currencies[1], fees[0]));
			labelPool(getPool(currencies[1], currencies[2], fees[1]));
		}
	}

	function findBestPoolForExactIn(
		Currency currencyIn,
		Currency currencyOut,
		uint256 amountIn
	) public view returns (IUniswapV3Pool pool, uint24 fee, uint256 amountOut) {
		vm.assume(amountIn != 0);

		uint24[] memory fees = getPoolFees();

		for (uint256 i; i < fees.length; ++i) {
			uint24 feeCurrent = fees[i];
			IUniswapV3Pool poolCurrent = getPool(currencyIn, currencyOut, feeCurrent);
			if (!isContract(address(poolCurrent)) || poolCurrent.liquidity() == 0) continue;

			try
				UNISWAP_V3_QUOTER.quoteExactInputSingle(
					IQuoter.QuoteExactInputSingleParams({
						currencyIn: currencyIn,
						currencyOut: currencyOut,
						amountIn: amountIn,
						fee: fee,
						sqrtPriceLimitX96: 0
					})
				)
			returns (uint256 amountOutCurrent, uint160, uint32, uint256) {
				if (amountOutCurrent > amountOut) {
					pool = poolCurrent;
					fee = feeCurrent;
					amountOut = amountOutCurrent;
				}
			} catch {}
		}
	}

	function findBestPoolForExactOut(
		Currency currencyIn,
		Currency currencyOut,
		uint256 amountOut
	) public view returns (IUniswapV3Pool pool, uint24 fee, uint256 amountIn) {
		vm.assume(amountOut != 0);

		amountIn = MAX_UINT256;

		uint24[] memory fees = getPoolFees();

		for (uint256 i; i < fees.length; ++i) {
			uint24 feeCurrent = fees[i];
			IUniswapV3Pool poolCurrent = getPool(currencyOut, currencyIn, feeCurrent);
			if (!isContract(address(poolCurrent)) || poolCurrent.liquidity() == 0) continue;

			try
				UNISWAP_V3_QUOTER.quoteExactOutputSingle(
					IQuoter.QuoteExactOutputSingleParams({
						currencyIn: currencyIn,
						currencyOut: currencyOut,
						amountOut: amountOut,
						fee: fee,
						sqrtPriceLimitX96: 0
					})
				)
			returns (uint256 amountInCurrent, uint160, uint32, uint256) {
				if (amountInCurrent != 0 && amountInCurrent < amountIn) {
					pool = poolCurrent;
					fee = feeCurrent;
					amountIn = amountInCurrent;
				}
			} catch {}
		}
	}

	function tickBounds(
		IUniswapV3Pool pool,
		uint8 distance
	) public view returns (int24 tickCurrent, int24 tickLower, int24 tickUpper) {
		(, tickCurrent, , , , , ) = pool.slot0();
		int24 tickSpacing = pool.tickSpacing();
		int24 dist = int8(distance) * tickSpacing;

		tickCurrent = TickMath.compress(tickCurrent, tickSpacing);
		tickLower = tickCurrent - dist;
		tickUpper = tickCurrent + dist;
	}

	function getMaxAmountInForPool(IUniswapV3Pool pool) public view returns (uint256 amount0, uint256 amount1) {
		(, int24 tickLower, int24 tickUpper) = tickBounds(pool, 1);
		return getMaxAmountInForPool(pool, tickLower, tickUpper);
	}

	function getMaxAmountInForPool(
		IUniswapV3Pool pool,
		int24 tickLower,
		int24 tickUpper
	) public view returns (uint256 amount0, uint256 amount1) {
		uint128 liquidity = pool.liquidity();
		(uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

		uint160 sqrtPriceX96Lower = TickMath.getSqrtRatioAtTick(tickLower);
		uint160 sqrtPriceX96Upper = TickMath.getSqrtRatioAtTick(tickUpper);

		amount0 = LiquidityAmounts.getAmount0ForLiquidity(sqrtPriceX96Lower, sqrtPriceX96, liquidity);
		amount1 = LiquidityAmounts.getAmount1ForLiquidity(sqrtPriceX96Upper, sqrtPriceX96, liquidity);
	}

	function getPoolWithMostLiquidity(
		Currency currencyA,
		Currency currencyB
	) public view returns (IUniswapV3Pool pool, uint24 fee, uint128 liquidity) {
		uint24[] memory fees = getPoolFees();

		for (uint256 i; i < fees.length; ++i) {
			IUniswapV3Pool poolCurrent = getPool(currencyA, currencyB, fees[i]);
			if (!isContract(address(poolCurrent))) continue;

			uint128 liquidityCurrent = poolCurrent.liquidity();
			if (liquidityCurrent > liquidity) {
				liquidity = liquidityCurrent;
				pool = poolCurrent;
				fee = fees[i];
			}
		}
	}

	function getPool(Currency currency0, Currency currency1, uint24 fee) public view returns (IUniswapV3Pool) {
		return UNISWAP_V3_FACTORY.getPool(currency0, currency1, fee);
	}

	function labelPool(IUniswapV3Pool pool) public {
		if (isContract(address(pool))) {
			vm.label(
				address(pool),
				string.concat(
					"UNI-V3: ",
					pool.token0().symbol(),
					"/",
					pool.token1().symbol(),
					" ",
					parseFeeString(pool.fee())
				)
			);
		}
	}

	function parseFeeString(uint24 fee) public pure returns (string memory feeStr) {
		feeStr = string.concat(
			Strings.toString(fee / 100),
			fee % 100 != 0 ? string.concat(".", Strings.toString((fee / 10) % 10), Strings.toString(fee % 10)) : "",
			"bps"
		);
	}

	function encodePath(Currency[] memory currencies, uint24[] memory fees) public pure returns (bytes memory path) {
		return encodePath(currencies, fees, false);
	}

	function encodePath(
		Currency[] memory currencies,
		uint24[] memory fees,
		bool reverse
	) public pure returns (bytes memory path) {
		vm.assertEq(currencies.length - 1, fees.length, "!length");

		if (reverse) {
			currencies = currencies.reverse();
			fees = fees.reverse();
		}

		path = abi.encodePacked(currencies[0]);

		for (uint256 i; i < fees.length; ++i) {
			path = abi.encodePacked(path, fees[i], currencies[i + 1]);
		}
	}

	function getPoolFees() public pure returns (uint24[] memory fees) {
		fees = new uint24[](4);
		fees[0] = FEE_LOWEST;
		fees[1] = FEE_LOW;
		fees[2] = FEE_MEDIUM;
		fees[3] = FEE_HIGH;
	}

	function getPoolFees(uint24 fee0) public pure returns (uint24[] memory fees) {
		fees = new uint24[](1);
		fees[0] = fee0;
	}

	function getPoolFees(uint24 fee0, uint24 fee1) public pure returns (uint24[] memory fees) {
		fees = new uint24[](2);
		fees[0] = fee0;
		fees[1] = fee1;
	}

	function getPoolFees(uint24 fee0, uint24 fee1, uint24 fee2) public pure returns (uint24[] memory fees) {
		fees = new uint24[](3);
		fees[0] = fee0;
		fees[1] = fee1;
		fees[2] = fee2;
	}

	function getPoolFees(
		uint24 fee0,
		uint24 fee1,
		uint24 fee2,
		uint24 fee3
	) public pure returns (uint24[] memory fees) {
		fees = new uint24[](4);
		fees[0] = fee0;
		fees[1] = fee1;
		fees[2] = fee2;
		fees[3] = fee3;
	}
}
