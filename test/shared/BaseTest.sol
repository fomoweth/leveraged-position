// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {ISTETH} from "src/interfaces/external/token/ISTETH.sol";
import {Currency} from "src/types/Currency.sol";

import {Assertions} from "./extensions/Assertions.sol";
import {Common} from "./extensions/Common.sol";
import {Fork} from "./extensions/Fork.sol";
import {ProxyHelper} from "./extensions/ProxyHelper.sol";

abstract contract BaseTest is Test, Assertions, Common, Fork, ProxyHelper {
	using stdStorage for StdStorage;

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

	function setUp() public virtual {
		configure();
		labelAll();
	}

	function configure() internal virtual override {
		if (block.chainid == 31337) vm.chainId(ETHEREUM_CHAIN_ID);

		super.configure();
		fork();
	}

	function revertToState() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToState(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function revertToStateAndDelete() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToStateAndDelete(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function makeAccount(string memory name) internal virtual override returns (Account memory account) {
		deal((account = super.makeAccount(name)).addr, 100 ether);
	}

	function setApproval(Currency currency, address account, address spender) internal virtual impersonate(account) {
		currency.approve(spender, MAX_UINT256);
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
