// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommonBase} from "forge-std/Base.sol";

import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Currency} from "src/types/Currency.sol";

import {Constants} from "./Constants.sol";

abstract contract Common is CommonBase, Constants {
	using CurrencyNamer for Currency;

	uint256 internal snapshotId = MAX_UINT256;

	modifier impersonate(address account) {
		vm.startPrank(account);
		_;
		vm.stopPrank();
	}

	function revertToState() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToState(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function revertToStateAndDelete() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToStateAndDelete(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function setApprovals(
		Currency[] memory currencies,
		address account,
		address spender
	) internal virtual impersonate(account) {
		for (uint256 i; i < currencies.length; ++i) {
			currencies[i].approve(spender, MAX_UINT256);
		}
	}

	function labelCurrency(Currency currency) internal virtual {
		label(Currency.unwrap(currency), currency.symbol());
	}

	function label(address target, string memory name) internal virtual {
		if (target != address(0) && bytes10(bytes(vm.getLabel(target))) == UNLABELED_PREFIX) {
			vm.label(target, name);
		}
	}

	function isContract(address target) internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := iszero(iszero(extcodesize(target)))
		}
	}

	function bytes32ToAddress(bytes32 input) internal pure returns (address output) {
		return address(uint160(uint256(input)));
	}

	function addressToBytes32(address input) internal pure returns (bytes32 output) {
		return bytes32(bytes20(input));
	}

	function emptyData() internal pure returns (bytes calldata data) {
		assembly ("memory-safe") {
			data.length := 0
		}
	}

	function getCurrencies(Currency currency0, Currency currency1) public pure returns (Currency[] memory currencies) {
		currencies = new Currency[](2);
		currencies[0] = currency0;
		currencies[1] = currency1;
	}

	function getCurrencies(
		Currency currency0,
		Currency currency1,
		Currency currency2
	) public pure returns (Currency[] memory currencies) {
		currencies = new Currency[](3);
		currencies[0] = currency0;
		currencies[1] = currency1;
		currencies[2] = currency2;
	}

	function getCurrencies(
		Currency currency0,
		Currency currency1,
		Currency currency2,
		Currency currency3
	) public pure returns (Currency[] memory currencies) {
		currencies = new Currency[](4);
		currencies[0] = currency0;
		currencies[1] = currency1;
		currencies[2] = currency2;
		currencies[3] = currency3;
	}

	function getCurrencies(
		Currency currency0,
		Currency currency1,
		Currency currency2,
		Currency currency3,
		Currency currency4
	) public pure returns (Currency[] memory currencies) {
		currencies = new Currency[](5);
		currencies[0] = currency0;
		currencies[1] = currency1;
		currencies[2] = currency2;
		currencies[3] = currency3;
		currencies[4] = currency4;
	}
}
