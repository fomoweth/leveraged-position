// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {ISTETH} from "src/interfaces/external/token/ISTETH.sol";
import {Currency} from "src/types/Currency.sol";

import {Assertions} from "./extensions/Assertions.sol";
import {Fork} from "./extensions/Fork.sol";

abstract contract BaseTest is Test, Assertions, Fork {
	using stdStorage for StdStorage;

	bytes32 internal constant STETH_TOTAL_SHARES_SLOT =
		0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;

	function setUp() public virtual {
		configure();
		labelAll();
	}

	function makeAccount(string memory name) internal virtual override returns (Account memory account) {
		deal((account = super.makeAccount(name)).addr, 100 ether);
	}

	function deal(Currency currency, address account, uint256 amount) internal virtual {
		deal(currency, account, amount, false);
	}

	function deal(Currency currency, address account, uint256 amount, bool adjust) internal virtual {
		if (currency.isZero() || amount == 0) return;

		if (currency.isNative()) {
			vm.deal(account, amount);
		} else if (currency == STETH) {
			address token = currency.toAddress();
			uint256 balancePrior = ISTETH(token).sharesOf(account);
			bytes32 balanceSlot = keccak256(abi.encode(account, uint256(0)));

			vm.store(token, balanceSlot, bytes32(amount));
			assertEq(ISTETH(token).sharesOf(account), amount, "!deal");

			if (adjust) {
				uint256 totalSupply = currency.totalSupply();

				if (amount < balancePrior) {
					totalSupply -= (balancePrior - amount);
				} else {
					totalSupply += (amount - balancePrior);
				}

				vm.store(token, STETH_TOTAL_SHARES_SLOT, bytes32(totalSupply));
			}
		} else if (currency == AAVE) {
			vm.assume(amount <= MAX_UINT104);

			address token = currency.toAddress();
			uint256 balancePrior = currency.balanceOf(account);
			bytes32 balanceSlot = keccak256(abi.encode(account, uint256(0)));

			vm.store(token, balanceSlot, bytes32(amount));
			assertEq(currency.balanceOf(account), amount, "!deal");

			if (adjust) {
				uint256 totalSupply = currency.totalSupply();

				if (amount < balancePrior) {
					totalSupply -= (balancePrior - amount);
				} else {
					totalSupply += (amount - balancePrior);
				}

				vm.store(token, bytes32(uint256(2)), bytes32(totalSupply));
			}
		} else {
			deal(currency.toAddress(), account, amount, adjust);
		}
	}
}
