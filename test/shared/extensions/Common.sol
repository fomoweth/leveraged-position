// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Vm} from "lib/forge-std/src/Vm.sol";

import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Currency} from "src/types/Currency.sol";

import {Constants} from "./Constants.sol";

abstract contract Common is Constants {
	using CurrencyNamer for Currency;

	Vm private constant vm = Vm(VM);

	function labelCurrency(Currency currency) internal virtual {
		label(currency.toAddress(), currency.symbol());
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

	function randomBytes(uint256 seed) internal pure returns (bytes memory result) {
		assembly ("memory-safe") {
			mstore(0x00, seed)
			let r := keccak256(0x00, 0x20)

			if lt(byte(2, r), 0x20) {
				result := mload(0x40)
				let n := and(r, 0x7f)
				mstore(result, n)
				codecopy(add(result, 0x20), byte(1, r), add(n, 0x40))
				mstore(0x40, add(add(result, 0x40), n))
			}
		}
	}

	function encodePrivateKey(string memory key) internal pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(key)));
	}

	function encodeSlot(bytes32 slot, bytes32 key) internal pure returns (bytes32) {
		return keccak256(abi.encode(key, slot));
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
