// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IConfigurator} from "src/interfaces/IConfigurator.sol";
import {ILender} from "src/interfaces/ILender.sol";
import {MASK_104_BITS, MASK_40_BITS} from "src/libraries/BitMasks.sol";
import {BytesLib} from "src/libraries/BytesLib.sol";
import {TypeConversion} from "src/libraries/TypeConversion.sol";
import {Currency} from "src/types/Currency.sol";
import {Chain} from "src/base/Chain.sol";
import {Initializable} from "src/base/Initializable.sol";
import {Validations} from "src/base/Validations.sol";

/// @title Lender

abstract contract Lender is ILender, Chain, Initializable, Validations {
	using BytesLib for bytes;

	address internal immutable POOL;

	address internal immutable REWARDS_CONTROLLER;

	address internal immutable PRICE_ORACLE;

	bytes32 public immutable PROTOCOL;

	uint256 public constant REVISION = 0x01;

	IConfigurator internal configurator;

	constructor(bytes32 _protocol, address _pool, address _priceOracle, address _rewardsController) {
		disableInitializer();
		PROTOCOL = verifyBytes32(_protocol);
		POOL = verifyContract(_pool);
		PRICE_ORACLE = verifyContract(_priceOracle);
		REWARDS_CONTROLLER = verifyContract(_rewardsController);
	}

	function initialize(bytes calldata params) external initializer {
		configurator = IConfigurator(verifyContract(params.toAddress(0)));
	}

	function approveIfNeeded(Currency currency, address spender, uint256 amount) internal virtual {
		if (currency.allowance(address(this), spender) < amount) {
			currency.approve(spender, amount);
		}
	}

	function encodeCallResult(
		int104 delta,
		uint104 reserveIndex,
		uint40 accrualTime
	) internal pure returns (int256 encoded) {
		assembly ("memory-safe") {
			encoded := or(
				add(shl(208, and(MASK_40_BITS, accrualTime)), shl(104, and(MASK_104_BITS, reserveIndex))),
				and(MASK_104_BITS, delta)
			)
		}
	}

	function getRevision() internal pure virtual override returns (uint256) {
		return REVISION;
	}
}
