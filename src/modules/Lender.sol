// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILender} from "src/interfaces/ILender.sol";
import {MASK_104_BITS, MASK_40_BITS} from "src/libraries/BitMasks.sol";
import {Errors} from "src/libraries/Errors.sol";
import {Currency} from "src/types/Currency.sol";
import {Chain} from "src/base/Chain.sol";

/// @title Lender

abstract contract Lender is ILender, Chain {
	using Errors for address;
	using Errors for bytes32;

	address internal immutable POOL;

	address internal immutable REWARDS_CONTROLLER;

	address internal immutable PRICE_ORACLE;

	bytes32 public immutable PROTOCOL;

	constructor(bytes32 _protocol, address _pool, address _priceOracle, address _rewardsController) {
		PROTOCOL = _protocol.verifyBytes32();
		POOL = _pool.verifyContract();
		PRICE_ORACLE = _priceOracle.verifyContract();
		REWARDS_CONTROLLER = _rewardsController.verifyContract();
	}

	function approveIfNeeded(Currency currency, address spender, uint256 amount) internal virtual {
		if (currency.allowance(address(this), spender) < amount) {
			currency.approve(spender, amount);
		}
	}

	function encodeCallResult(int104 delta, uint104 reserveIndex, uint40 accrualTime) internal pure returns (int256 r) {
		assembly ("memory-safe") {
			r := or(
				add(shl(208, and(MASK_40_BITS, accrualTime)), shl(104, and(MASK_104_BITS, reserveIndex))),
				and(MASK_104_BITS, delta)
			)
		}
	}
}
