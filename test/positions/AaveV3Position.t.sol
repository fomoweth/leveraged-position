// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2 as console} from "forge-std/Test.sol";

import {IUniswapV3Pool} from "src/interfaces/external/uniswap/v3/IUniswapV3Pool.sol";
import {ILeveragedPosition} from "src/interfaces/ILeveragedPosition.sol";
import {ILender} from "src/interfaces/ILender.sol";
import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Math} from "src/libraries/Math.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {PositionMath} from "src/libraries/PositionMath.sol";
import {Currency} from "src/types/Currency.sol";
import {AaveV3Lender} from "src/modules/AaveV3Lender.sol";
import {LeveragedPosition} from "src/LeveragedPosition.sol";

import {PositionUtils} from "test/shared/utils/PositionUtils.sol";
import {AaveV3Config, AaveMarket} from "test/shared/Protocols.sol";
import {PositionTest} from "./PositionTest.sol";

// forge test --match-path test/positions/AaveV3Position.t.sol --chain 1 -vv

abstract contract AaveV3PositionTest is PositionTest {
	using CurrencyNamer for Currency;
	using Math for uint256;
	using PercentageMath for uint256;
	using PositionMath for uint256;
	using PositionUtils for LeveragedPosition;

	mapping(Currency underlying => AaveMarket market) internal reservesMap;

	AaveMarket[] internal reservesList;

	AaveV3Lender internal lender;

	string internal constant AAVE_V3_AAVE_KEY = "aave";
	string internal constant AAVE_V3_ETHERFI_KEY = "etherfi";
	string internal constant AAVE_V3_LIDO_KEY = "lido";

	bytes32 internal constant AAVE_V3_AAVE_ID = "AAVE-V3: Aave";
	bytes32 internal constant AAVE_V3_ETHERFI_ID = "AAVE-V3: EtherFi";
	bytes32 internal constant AAVE_V3_LIDO_ID = "AAVE-V3: Lido";

	uint256 internal constant PRINCIPAL_IN_BASE = 10000 * 1e8;

	function setUp() public virtual override {
		super.setUp();

		lender = deployAaveV3Lender(
			protocolId,
			address(aaveV3.pool),
			address(aaveV3.oracle),
			address(aaveV3.rewardsController)
		);

		position = deployPosition(protocolId, 0, 0, address(this));
	}

	function configure() internal virtual override {
		super.configure();

		configureAaveV3(protocolKey);
		setUpMarkets(protocolKey);

		vm.prank(aaveV3.addressesProvider.getACLAdmin());
		aaveV3.addressesProvider.setACLAdmin(address(this));
	}

	function test_decreaseLiquidity() public virtual {
		uint256 deltaRatio = 2500;

		uint256 amountToDeposit = PRINCIPAL_IN_BASE.convertFromBase(position.getCollateralPrice(), collateralScale);

		(, , uint16 ltv) = position.ltvBounds();
		uint256 amountOut = amountToDeposit.percentDiv(BPS - ltv) - amountToDeposit;

		PositionState memory increaseState = executeIncreaseLiquidity(amountToDeposit, setPath(amountOut, false));

		advanceTime(3 days);

		(Currency[] memory currencies, uint24[] memory fees) = routes.parsePath(increaseState.path);

		uint256 amountToWithdraw = increaseState.principal.percentMul(deltaRatio);
		PositionState memory decreaseState = executeDecreaseLiquidity(
			amountToWithdraw,
			true,
			routes.encodePath(currencies, fees, true)
		);

		uint256 collateralUsageDelta = increaseState.collateralUsage < decreaseState.collateralUsage
			? decreaseState.collateralUsage - increaseState.collateralUsage
			: increaseState.collateralUsage - decreaseState.collateralUsage;

		assertEq(collateralAsset.balanceOfSelf(), amountToWithdraw, "!amountToWithdraw");
		assertGt(increaseState.principal, decreaseState.principal, "!principal");
		assertGt(increaseState.totalCollateral, decreaseState.totalCollateral, "!totalCollateral");
		assertGt(increaseState.totalDebt, decreaseState.totalDebt, "!totalDebt");
		assertGt(increaseState.availableLiquidity, decreaseState.availableLiquidity, "!availableLiquidity");
		assertGt(increaseState.availableBorrows, decreaseState.availableBorrows, "!availableBorrows");
		assertEq(increaseState.ltv, decreaseState.ltv, "!ltv");
		assertLt(collateralUsageDelta, 100, "!collateralUsage");
		assertCloseTo(increaseState.collateralUsage, decreaseState.collateralUsage, "!collateralUsage");
	}

	function test_increaseLiquidity() public virtual {
		uint256 amountToDeposit = PRINCIPAL_IN_BASE.convertFromBase(position.getCollateralPrice(), collateralScale);

		(, , uint16 loanToValue) = position.ltvBounds();
		uint256 amountOut = amountToDeposit.percentDiv(BPS - loanToValue) - amountToDeposit;
		bytes memory path = setPath(amountOut, false);

		PositionState memory state = executeIncreaseLiquidity(amountToDeposit, path);

		(
			uint256 totalCollateralBase,
			uint256 totalDebtBase,
			uint256 availableBorrowsBase,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		) = aaveV3.pool.getUserAccountData(address(position));

		assertCloseTo(state.totalCollateralInBase, totalCollateralBase, "!totalCollateralInBase");
		assertCloseTo(state.totalDebtInBase, totalDebtBase, "!totalDebtInBase");
		assertCloseTo(state.availableBorrowsInBase, availableBorrowsBase, "!availableBorrowsInBase");
		assertEq(state.liquidationFactor, currentLiquidationThreshold, "!liquidationFactor");
		assertEq(state.collateralFactor, ltv, "!collateralFactor");
		assertCloseTo(state.healthFactor, healthFactor, "!healthFactor");
		assertCloseTo(state.collateralUsage, state.ltv, "!collateralUsage");
	}

	function setUpMarkets(string memory key) internal virtual override {
		AaveMarket[] memory markets = getAaveV3Markets(key);

		for (uint256 i; i < markets.length; ++i) {
			AaveMarket memory market = markets[i];

			bool isCollateral = market.ltv > minCollateralFactor() && market.isCollateral;
			bool isBorrowable = market.isBorrowable;
			if (!isCollateral && !isBorrowable) continue;

			uint256 price = getAssetPrice(market.underlying);
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

	function setPath(uint256 amountOut, bool reverse) internal virtual override returns (bytes memory path) {
		(path, ) = !reverse
			? routes.findRouteForExactOut(liabilityAsset, collateralAsset, amountOut)
			: routes.findRouteForExactOut(collateralAsset, liabilityAsset, amountOut);
	}

	function setSupplyCap(Currency currency, uint256 supplyCap) internal virtual override {
		aaveV3.poolConfigurator.setSupplyCap(currency, supplyCap);
	}

	function setBorrowCap(Currency currency, uint256 borrowCap) internal virtual override {
		aaveV3.poolConfigurator.setBorrowCap(currency, borrowCap);
	}

	function getAssetPrice(Currency currency) internal view virtual returns (uint256) {
		return aaveV3.oracle.getAssetPrice(currency);
	}
}

contract AaveV3Test is AaveV3PositionTest {
	function setUp() public virtual override {
		setProtocol(AAVE_V3_AAVE_KEY, AAVE_V3_AAVE_ID);
		super.setUp();
	}

	function PROTOCOL_KEY() internal pure virtual override returns (string memory) {
		return AAVE_V3_AAVE_KEY;
	}

	function PROTOCOL_ID() internal pure virtual override returns (bytes32) {
		return AAVE_V3_AAVE_ID;
	}

	function minCollateralFactor() internal pure virtual override returns (uint256) {
		return 6000;
	}
}

contract AaveV3EtherFiTest is AaveV3PositionTest {
	using CurrencyNamer for Currency;

	function setUp() public virtual override {
		setProtocol(AAVE_V3_ETHERFI_KEY, AAVE_V3_ETHERFI_ID);

		super.setUp();
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

	function PROTOCOL_KEY() internal pure virtual override returns (string memory) {
		return AAVE_V3_ETHERFI_KEY;
	}

	function PROTOCOL_ID() internal pure virtual override returns (bytes32) {
		return AAVE_V3_ETHERFI_ID;
	}
}

contract AaveV3LidoTest is AaveV3PositionTest {
	function setUp() public virtual override {
		setProtocol(AAVE_V3_LIDO_KEY, AAVE_V3_LIDO_ID);
		super.setUp();
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

	function PROTOCOL_KEY() internal pure virtual override returns (string memory) {
		return AAVE_V3_LIDO_KEY;
	}

	function PROTOCOL_ID() internal pure virtual override returns (bytes32) {
		return AAVE_V3_LIDO_ID;
	}
}
