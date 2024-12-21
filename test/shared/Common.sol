// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {ISTETH} from "src/interfaces/external/token/ISTETH.sol";
import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Currency} from "src/types/Currency.sol";

import {Assertions} from "./Assertions.sol";
import {Constants} from "./Constants.sol";

abstract contract Common is Test, Assertions, Constants {
	using CurrencyNamer for Currency;

	uint256 internal forkId;
	uint256 internal snapshotId = MAX_UINT256;

	modifier impersonate(address account) {
		vm.startPrank(account);
		_;
		vm.stopPrank();
	}

	modifier onlyEthereum() {
		vm.skip(block.chainid != ETHEREUM_CHAIN_ID);
		_;
	}

	modifier onlyOptimism() {
		vm.skip(block.chainid != OPTIMISM_CHAIN_ID);
		_;
	}

	modifier onlyPolygon() {
		vm.skip(block.chainid != POLYGON_CHAIN_ID);
		_;
	}

	modifier onlyArbitrum() {
		vm.skip(block.chainid != ARBITRUM_CHAIN_ID);
		_;
	}

	function setUp() public virtual {}

	function revertToState() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToState(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function revertToStateAndDelete() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToStateAndDelete(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function advanceBlock(uint256 blocks) internal virtual returns (uint256) {
		vm.roll(block.number + blocks);

		return vm.getBlockNumber();
	}

	function advanceTime(uint256 time) internal virtual returns (uint256) {
		vm.warp(block.timestamp + time);

		return vm.getBlockTimestamp();
	}

	function makeAccount(string memory name) internal virtual override returns (Account memory account) {
		deal((account = super.makeAccount(name)).addr, 100 ether);
	}

	function deal(Currency currency, address account, uint256 amount, bool adjust) internal virtual {
		if (amount == 0) return;

		if (currency.isNative()) {
			deal(account, amount);
		} else if (currency == STETH) {
			ISTETH steth = ISTETH(Currency.unwrap(currency));

			uint256 ethAmount = steth.getPooledEthByShares(amount);
			deal(address(this), ethAmount);

			uint256 received = steth.submit{value: ethAmount}(address(0));

			if (account != address(this)) currency.transfer(account, received);
		} else {
			deal(Currency.unwrap(currency), account, amount, adjust);
		}
	}

	function deal(Currency currency, address account, uint256 amount) internal virtual {
		deal(currency, account, amount, false);
	}

	function deal(Currency currency, uint256 amount) internal virtual {
		deal(currency, address(this), amount, false);
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
