// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Math} from "src/libraries/Math.sol";
import {PositionMath} from "src/libraries/PositionMath.sol";
import {Currency} from "src/types/Currency.sol";
import {AaveV3Lender} from "src/modules/AaveV3Lender.sol";

import {MockLeveragedPosition} from "test/mocks/MockLeveragedPosition.sol";
import {PositionUtils} from "test/shared/utils/PositionUtils.sol";
import {AaveV3Config, AaveMarket} from "test/shared/Protocols.sol";
import {PositionTest} from "./PositionTest.sol";

// forge test --match-path test/positions/AaveV3Position.t.sol --chain 1 -vv

abstract contract AaveV3PositionTest is PositionTest {
	using Math for uint256;
	using PositionMath for uint256;

	mapping(Currency underlying => AaveMarket market) internal reservesMap;

	AaveMarket[] internal reservesList;

	AaveV3Lender internal lender;

	string internal constant AAVE_V3_AAVE_KEY = "aave";
	string internal constant AAVE_V3_ETHERFI_KEY = "etherfi";
	string internal constant AAVE_V3_LIDO_KEY = "lido";

	bytes32 internal constant AAVE_V3_AAVE_ID = "AAVE-V3: Aave";
	bytes32 internal constant AAVE_V3_ETHERFI_ID = "AAVE-V3: EtherFi";
	bytes32 internal constant AAVE_V3_LIDO_ID = "AAVE-V3: Lido";

	function setUp() public virtual override {
		super.setUp();

		lender = deployAaveV3Lender(
			protocolId,
			address(aaveV3.pool),
			address(aaveV3.oracle),
			address(aaveV3.rewardsController)
		);

		(collateralAsset, liabilityAsset) = randomReserves();

		collateralScale = 10 ** collateralAsset.decimals();
		liabilityScale = 10 ** liabilityAsset.decimals();
	}

	function configure() internal virtual override {
		super.configure();

		configureAaveV3(protocolKey);
		setUpMarkets(protocolKey);

		vm.prank(aaveV3.addressesProvider.getACLAdmin());
		aaveV3.addressesProvider.setACLAdmin(address(this));
	}

	function setUpMarkets(string memory key) internal virtual override {
		AaveMarket[] memory markets = getAaveV3Markets(key);

		for (uint256 i; i < markets.length; ++i) {
			AaveMarket memory market = markets[i];

			bool isCollateral = market.ltv > minCollateralFactor() && market.isCollateral;
			bool isBorrowable = market.isBorrowable;
			if (!isCollateral && !isBorrowable) continue;

			uint256 price = aaveV3.oracle.getAssetPrice(market.underlying);
			uint256 scale = 10 ** market.underlying.decimals();

			uint256 liquidity = market.underlying.balanceOf(address(market.aToken));
			uint256 liquidityInBase = liquidity.convertToBase(price, scale);
			uint256 delta = minLiquidity().zeroFloorSub(liquidityInBase);

			if (delta != 0) {
				deal(market.underlying, address(this), delta.convertFromBase(price, scale));
				market.underlying.approve(address(aaveV3.pool), MAX_UINT256);
				aaveV3.pool.supply(market.underlying, market.underlying.balanceOfSelf(), address(this), 0);
			}

			labelAaveMarket(market);

			reservesList.push((reservesMap[market.underlying] = market));
			allAssets.push(market.underlying);

			if (isCollateral) collateralAssets.push(market.underlying);
			if (isBorrowable) liabilityAssets.push(market.underlying);
		}
	}
}

contract AaveV3Test is AaveV3PositionTest {
	function setUp() public virtual override {
		setProtocol(AAVE_V3_AAVE_KEY, AAVE_V3_AAVE_ID);
		super.setUp();
	}

	function setUpMarkets(string memory key) internal virtual override {
		super.setUpMarkets(key);

		collateralAssets = [WETH, WSTETH, WEETH, WBTC, AAVE, LINK, DAI, USDC, USDT];
		liabilityAssets = [WETH, WSTETH, WEETH, WBTC, LINK, DAI, FRAX, USDC, USDT];
	}

	function test_increaseLiquidity_revertsWithInvalidCollateralAsset() public virtual override {
		while (true) if (reservesMap[(collateralAsset = randomLiability())].ltv == 0) break;
		liabilityAsset = randomLiability(collateralAsset);
		collateralScale = 10 ** collateralAsset.decimals();
		liabilityScale = 10 ** liabilityAsset.decimals();

		super.test_increaseLiquidity_revertsWithInvalidCollateralAsset();
	}

	function setPath(uint256 amountOut, bool reverse) internal virtual override returns (bytes memory path) {
		(path, ) = !reverse
			? routes.findRouteForExactOut(liabilityAsset, collateralAsset, amountOut)
			: routes.findRouteForExactOut(collateralAsset, liabilityAsset, amountOut);
	}
}

contract AaveV3EtherFiTest is AaveV3PositionTest {
	function setUp() public virtual override {
		setProtocol(AAVE_V3_ETHERFI_KEY, AAVE_V3_ETHERFI_ID);

		super.setUp();
	}

	function setUpMarkets(string memory key) internal virtual override {
		super.setUpMarkets(key);

		liabilityAssets = [USDC, FRAX];
	}

	function test_increaseLiquidity_revertsWithInvalidCollateralAsset() public virtual override {
		collateralAsset = USDC;
		liabilityAsset = FRAX;
		collateralScale = 1e6;
		liabilityScale = 1e18;

		super.test_increaseLiquidity_revertsWithInvalidCollateralAsset();
	}

	function setPath(uint256, bool reverse) internal virtual override returns (bytes memory) {
		Currency[] memory currencies;
		uint24[] memory fees;

		if (liabilityAsset == USDC) {
			currencies = routes.getCurrencies(WEETH, WETH, USDC);
			fees = routes.getPoolFees(100, 500);
		} else if (liabilityAsset == FRAX) {
			currencies = routes.getCurrencies(WEETH, WETH, USDC, FRAX);
			fees = routes.getPoolFees(100, 500, 500);
		}

		return routes.encodePath(currencies, fees, reverse);
	}
}

contract AaveV3LidoTest is AaveV3PositionTest {
	function setUp() public virtual override {
		setProtocol(AAVE_V3_LIDO_KEY, AAVE_V3_LIDO_ID);
		super.setUp();
	}

	function setUpMarkets(string memory key) internal virtual override {
		super.setUpMarkets(key);

		liabilityAssets = [WETH, USDC];
	}

	function test_increaseLiquidity_revertsWithInvalidCollateralAsset() public virtual override {
		collateralAsset = WETH;
		liabilityAsset = USDC;
		collateralScale = 1e18;
		liabilityScale = 1e6;

		super.test_increaseLiquidity_revertsWithInvalidCollateralAsset();
	}

	function setPath(uint256, bool reverse) internal virtual override returns (bytes memory) {
		Currency[] memory currencies;
		uint24[] memory fees;

		if (liabilityAsset == WETH) {
			currencies = routes.getCurrencies(WSTETH, WETH);
			fees = routes.getPoolFees(100);
		} else if (liabilityAsset == USDC) {
			currencies = routes.getCurrencies(WSTETH, WETH, USDC);
			fees = routes.getPoolFees(100, 500);
		}

		return routes.encodePath(currencies, fees, reverse);
	}
}
