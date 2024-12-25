// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MASK_160_BITS, MASK_24_BITS, MASK_8_BITS} from "src/libraries/BitMasks.sol";
import {CallbackValidation} from "src/libraries/CallbackValidation.sol";
import {Errors} from "src/libraries/Errors.sol";
import {Path} from "src/libraries/Path.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {Currency} from "src/types/Currency.sol";
import {Validations} from "./Validations.sol";

/// @title V3Swap
/// @notice Provides functions to interact with Uniswap V3 pools

abstract contract V3Swap is Validations {
	using Path for bytes;
	using SafeCast for uint256;

	bytes32 private constant UNISWAP_V3_POOL_INIT_CODE_HASH =
		0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

	address private constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
	address private constant UNISWAP_V3_QUOTER = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

	bytes4 private constant UNISWAP_V3_SWAP_CALLBACK_SELECTOR = 0xfa461e33;

	uint160 private constant MIN_SQRT_PRICE_LIMIT = 4295128740;
	uint160 private constant MAX_SQRT_PRICE_LIMIT = 1461446703485210103287273052203988822378723970341;

	modifier setUpCallback(address caller, bytes4 signature) {
		CallbackValidation.setUp(caller, signature);
		_;
	}

	modifier verifyCallback() {
		CallbackValidation.verify();
		_;
	}

	function uniswapV3SwapCallback(
		int256 amount0Delta,
		int256 amount1Delta,
		bytes calldata path
	) external verifyCallback {
		handleV3SwapCallback(amount0Delta, amount1Delta, path);
	}

	function exactOutputInternal(uint256 amountOut, bytes calldata path) internal virtual returns (uint256 amountIn) {
		(Currency currencyOut, Currency currencyIn, uint24 fee) = path.decodeFirstPool();

		bool zeroForOne = currencyIn < currencyOut;

		(int256 amount0Delta, int256 amount1Delta) = swap(
			computePool(currencyOut, currencyIn, fee),
			address(this),
			zeroForOne,
			-amountOut.toInt256(),
			path
		);

		uint256 amountOutReceived;
		(amountIn, amountOutReceived) = zeroForOne
			? (uint256(amount0Delta), uint256(-amount1Delta))
			: (uint256(amount1Delta), uint256(-amount0Delta));

		required(amountOutReceived == amountOut, Errors.InsufficientAmountOut.selector);
	}

	function swap(
		address pool,
		address recipient,
		bool zeroForOne,
		int256 amountSpecified,
		bytes calldata data
	)
		internal
		setUpCallback(pool, UNISWAP_V3_SWAP_CALLBACK_SELECTOR)
		returns (int256 amount0Delta, int256 amount1Delta)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x128acb0800000000000000000000000000000000000000000000000000000000) // swap(address,bool,int256,uint160,bytes)
			mstore(add(ptr, 0x04), and(recipient, 0xffffffffffffffffffffffffffffffffffffffff))
			mstore(add(ptr, 0x24), and(zeroForOne, 0xff))
			mstore(add(ptr, 0x44), amountSpecified)
			mstore(
				add(ptr, 0x64),
				xor(MAX_SQRT_PRICE_LIMIT, mul(xor(MIN_SQRT_PRICE_LIMIT, MAX_SQRT_PRICE_LIMIT), zeroForOne))
			)
			mstore(add(ptr, 0x84), 0xa0)
			mstore(add(ptr, 0xa4), data.length)
			calldatacopy(add(ptr, 0xc4), data.offset, data.length)

			if iszero(call(gas(), pool, 0x00, ptr, add(0xc4, data.length), 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amount0Delta := mload(0x00)
			amount1Delta := mload(0x20)

			mstore(0x40, add(ptr, add(0xe0, data.length)))
		}
	}

	function quoteExactInput(uint256 amountIn, bytes calldata path) internal view virtual returns (uint256 amountOut) {
		if (amountIn == 0) return 0;

		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xcdca175300000000000000000000000000000000000000000000000000000000) // quoteExactInput(bytes,uint256)
			mstore(add(ptr, 0x04), 0x40)
			mstore(add(ptr, 0x24), amountIn)
			mstore(add(ptr, 0x44), path.length)
			calldatacopy(add(ptr, 0x64), path.offset, path.length)

			if iszero(staticcall(gas(), UNISWAP_V3_QUOTER, ptr, add(0x64, path.length), 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amountOut := mload(0x00)
		}
	}

	function quoteExactOutput(uint256 amountOut, bytes calldata path) internal view virtual returns (uint256 amountIn) {
		if (amountOut == 0) return 0;

		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x2f80bb1d00000000000000000000000000000000000000000000000000000000) // quoteExactOutput(bytes,uint256)
			mstore(add(ptr, 0x04), 0x40)
			mstore(add(ptr, 0x24), amountOut)
			mstore(add(ptr, 0x44), path.length)
			calldatacopy(add(ptr, 0x64), path.offset, path.length)

			if iszero(staticcall(gas(), UNISWAP_V3_QUOTER, ptr, add(0x64, path.length), 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amountIn := mload(0x00)
		}
	}

	function computePool(Currency currency0, Currency currency1, uint24 fee) internal view returns (address pool) {
		assembly ("memory-safe") {
			if gt(currency0, currency1) {
				let temp := currency0
				currency0 := currency1
				currency1 := temp
			}

			let ptr := mload(0x40)

			mstore(ptr, add(hex"ff", shl(0x58, UNISWAP_V3_FACTORY)))
			mstore(add(ptr, 0x15), and(MASK_160_BITS, currency0))
			mstore(add(ptr, 0x35), and(MASK_160_BITS, currency1))
			mstore(add(ptr, 0x55), and(MASK_24_BITS, fee))
			mstore(add(ptr, 0x15), keccak256(add(ptr, 0x15), 0x60))
			mstore(add(ptr, 0x35), UNISWAP_V3_POOL_INIT_CODE_HASH)

			pool := and(MASK_160_BITS, keccak256(ptr, 0x55))

			// revert if the pool at computed address hasn't deployed yet
			if iszero(extcodesize(pool)) {
				mstore(0x00, 0x0ba98f1c) // PoolNotExists()
				revert(0x1c, 0x04)
			}
		}
	}

	function handleV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata path) internal virtual;
}
