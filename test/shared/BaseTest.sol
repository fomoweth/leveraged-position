// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {ISTETH} from "src/interfaces/external/token/ISTETH.sol";
import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Currency} from "src/types/Currency.sol";

import {Configured} from "config/Configured.sol";

import {Assertions} from "./extensions/Assertions.sol";
import {Common} from "./extensions/Common.sol";
import {ProxyHelper} from "./extensions/ProxyHelper.sol";

import {AaveV3Config, AaveMarket, CometConfig, CometMarket} from "./Protocols.sol";

abstract contract BaseTest is Test, Configured, Assertions, ProxyHelper {
	using CurrencyNamer for Currency;
	using stdStorage for StdStorage;

	uint256 internal forkId;

	uint256 internal snapshotId = MAX_UINT256;

	modifier impersonate(address account) {
		vm.startPrank(account);
		_;
		vm.stopPrank();
	}

	function setUp() public virtual {
		configure();
		labelAll();
	}

	function configure() internal virtual override {
		if (block.chainid == 31337) vm.chainId(1);

		super.configure();
		fork();
	}

	function fork() internal virtual {
		uint256 forkBlockNumber = getForkBlockNumber();

		if (forkBlockNumber != 0) {
			forkId = vm.createSelectFork(vm.rpcUrl(rpcAlias()), forkBlockNumber);
		} else {
			forkId = vm.createSelectFork(vm.rpcUrl(rpcAlias()));
		}

		vm.chainId(getChainId());
	}

	function revertToState() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToState(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function revertToStateAndDelete() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToStateAndDelete(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function advanceBlock(uint256 blocks) internal virtual {
		vm.roll(vm.getBlockNumber() + blocks);
		vm.warp(vm.getBlockTimestamp() + blocks * SECONDS_PER_BLOCK);
	}

	function advanceTime(uint256 time) internal virtual {
		vm.warp(vm.getBlockTimestamp() + time);
		vm.roll(vm.getBlockNumber() + time * SECONDS_PER_BLOCK);
	}

	function boundBlocks(uint256 blocks) internal pure returns (uint256) {
		return bound(blocks, 1, 7 days / SECONDS_PER_BLOCK);
	}

	function randomAsset(Currency exception) internal virtual returns (Currency) {
		return randomAsset(allAssets, exception);
	}

	function randomAsset() internal virtual returns (Currency) {
		return randomAsset(allAssets);
	}

	function randomAsset(Currency[] memory assets, Currency exception) internal virtual returns (Currency asset) {
		while (true) if ((asset = randomAsset(assets)) != exception) break;
	}

	function randomAsset(Currency[] memory assets) internal virtual returns (Currency) {
		vm.assume(assets.length != 0);
		return assets[vm.randomUint(0, assets.length - 1)];
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

	function makeAccount(string memory name) internal virtual override returns (Account memory account) {
		deal((account = super.makeAccount(name)).addr, 100 ether);
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

	function encodePrivateKey(string memory key) internal pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(key)));
	}

	function encodeSlot(bytes32 slot, bytes32 key) internal pure returns (bytes32) {
		return keccak256(abi.encode(key, slot));
	}

	function labelAll() internal virtual {
		vm.label(address(UNISWAP_V3_FACTORY), "Uniswap V3 Factory");
		vm.label(address(UNISWAP_V3_QUOTER), "Uniswap V3 Quoter");
		labelAaveV3();
		labelComet();
	}

	function labelAaveV3() internal virtual {
		if (bytes(aaveV3.context.network).length == 0) return;

		string memory prefix = string.concat("Aave V3 ", aaveV3.context.protocol, ": ");

		vm.label(aaveV3.aclAdmin, string.concat(prefix, "ACLAdmin"));
		vm.label(address(aaveV3.aclManager), string.concat(prefix, "ACLManager"));
		vm.label(address(aaveV3.addressesProvider), string.concat(prefix, "PoolAddressesProvider"));
		vm.label(address(aaveV3.dataProvider), string.concat(prefix, "PoolDataProvider"));
		vm.label(address(aaveV3.pool), string.concat(prefix, "Pool"));
		vm.label(address(aaveV3.oracle), string.concat(prefix, "PriceOracle"));
		vm.label(address(aaveV3.rewardsController), string.concat(prefix, "RewardsController"));
		vm.label(address(aaveV3.emissionManager), string.concat(prefix, "EmissionManager"));
		vm.label(address(aaveV3.collector), string.concat(prefix, "Collector"));
	}

	function labelAaveMarket(AaveMarket memory market) internal virtual {
		if (bytes(market.symbol).length == 0) return;

		string memory prefix = string.concat(aaveV3.context.abbreviation, market.symbol);

		vm.label(market.underlying.toAddress(), market.symbol);
		vm.label(address(market.aToken), string.concat("a", prefix));
		vm.label(address(market.vdToken), string.concat("variableDebt", prefix));
	}

	function labelComet() internal virtual {
		if (compV3.governor == address(0)) return;

		vm.label(compV3.governor, "CometGovernor");
		vm.label(address(compV3.configurator), "CometConfigurator");
		vm.label(address(compV3.rewards), "CometRewards");
	}

	function labelCometMarket(CometMarket memory market) internal virtual {
		if (bytes(market.symbol).length == 0) return;

		vm.label(market.underlying.toAddress(), market.base);
		vm.label(address(market.comet), market.symbol);

		for (uint256 i; i < market.assets.length; ++i) {
			vm.label(market.assets[i].underlying.toAddress(), market.assets[i].symbol);
		}
	}

	function labelCurrency(Currency currency) internal virtual {
		label(currency.toAddress(), currency.symbol());
	}

	function label(address target, string memory name) internal virtual {
		if (target != address(0) && bytes10(bytes(vm.getLabel(target))) == UNLABELED_PREFIX) {
			vm.label(target, name);
		}
	}
}
