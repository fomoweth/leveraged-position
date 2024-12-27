// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {CompoundV3Lender} from "src/modules/CompoundV3Lender.sol";

import {CometConfig, CometMarket, CometAsset} from "test/shared/Protocols.sol";
import {PositionTest} from "./PositionTest.sol";

// forge test --match-path test/positions/CompoundV3Position.t.sol --chain 1 -vv

abstract contract CompoundV3PositionTest is PositionTest {
	mapping(Currency underlying => CometAsset) internal reservesMap;

	CometAsset[] internal reservesList;
	CometMarket internal market;

	CompoundV3Lender internal lender;

	string internal constant COMP_V3_CUSDC_KEY = "cUSDCv3";
	string internal constant COMP_V3_CUSDT_KEY = "cUSDTv3";

	bytes32 internal constant COMP_V3_CUSDC_ID = "Compound-V3 cUSDCv3";
	bytes32 internal constant COMP_V3_CUSDT_ID = "Compound-V3 cUSDTv3";

	function setUp() public virtual override {
		super.setUp();

		lender = deployCompoundV3Lender(
			protocolId,
			address(market.comet),
			address(market.feed),
			address(compV3.rewards)
		);

		(collateralAsset, liabilityAsset) = randomReserves();

		collateralScale = 10 ** collateralAsset.decimals();
		liabilityScale = 10 ** liabilityAsset.decimals();
	}

	function configure() internal virtual override {
		super.configure();

		configureCompoundV3();
		setUpMarkets(protocolKey);

		vm.prank(compV3.governor);
		compV3.configurator.transferGovernor(address(this));
		assertEq(compV3.configurator.governor(), address(this), "!governor");

		compV3.configurator.setGovernor(address(market.comet), address(this));
		compV3.configurator.setPauseGuardian(address(market.comet), address(this));
	}

	function setUpMarkets(string memory key) internal virtual override {
		market = getCometMarket(key);

		CometAsset memory baseAsset = CometAsset({
			symbol: market.base,
			underlying: market.underlying,
			feed: market.feed,
			ltv: 0
		});

		reservesList.push((reservesMap[baseAsset.underlying] = baseAsset));
		allAssets.push(market.underlying);
		liabilityAssets.push(market.underlying);

		for (uint256 i; i < market.assets.length; ++i) {
			CometAsset memory asset = market.assets[i];
			reservesList.push((reservesMap[asset.underlying] = asset));
			allAssets.push(asset.underlying);
		}
	}
}

contract CompoundV3CUSDCTest is CompoundV3PositionTest {
	function setUp() public virtual override {
		setProtocol(COMP_V3_CUSDC_KEY, COMP_V3_CUSDC_ID);
		super.setUp();
	}

	function test_increaseLiquidity_revertsWithInvalidCollateralAsset() public virtual override {
		collateralAsset = USDC;
		liabilityAsset = WETH;
		collateralScale = 1e6;
		liabilityScale = 1e18;

		super.test_increaseLiquidity_revertsWithInvalidCollateralAsset();
	}

	function setUpMarkets(string memory key) internal virtual override {
		super.setUpMarkets(key);

		collateralAssets = [WETH, WSTETH, WBTC, LINK, UNI];
	}
}

contract CompoundV3CUSDTTest is CompoundV3PositionTest {
	function setUp() public virtual override {
		setProtocol(COMP_V3_CUSDT_KEY, COMP_V3_CUSDT_ID);
		super.setUp();
	}

	function test_increaseLiquidity_revertsWithInvalidCollateralAsset() public virtual override {
		collateralAsset = USDT;
		liabilityAsset = WETH;
		collateralScale = 1e6;
		liabilityScale = 1e18;

		super.test_increaseLiquidity_revertsWithInvalidCollateralAsset();
	}

	function setUpMarkets(string memory key) internal virtual override {
		super.setUpMarkets(key);

		collateralAssets = [WETH, WSTETH, WBTC, LINK, UNI];
	}
}
