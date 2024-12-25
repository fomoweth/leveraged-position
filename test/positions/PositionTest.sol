// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2 as console} from "forge-std/Test.sol";

import {ILeveragedPosition} from "src/interfaces/ILeveragedPosition.sol";
import {ILender} from "src/interfaces/ILender.sol";
import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Errors} from "src/libraries/Errors.sol";
import {Math} from "src/libraries/Math.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {PositionMath} from "src/libraries/PositionMath.sol";
import {WadRayMath} from "src/libraries/WadRayMath.sol";
import {Currency} from "src/types/Currency.sol";
import {AaveV3Lender} from "src/modules/AaveV3Lender.sol";
import {CompoundV3Lender} from "src/modules/CompoundV3Lender.sol";
import {Configurator} from "src/Configurator.sol";
import {PositionDeployer} from "src/PositionDeployer.sol";
import {PositionDescriptor} from "src/PositionDescriptor.sol";
import {LeveragedPosition} from "src/LeveragedPosition.sol";

import {PositionUtils} from "test/shared/utils/PositionUtils.sol";
import {Routes} from "test/shared/utils/Routes.sol";
import {BaseTest} from "test/shared/BaseTest.sol";

abstract contract PositionTest is BaseTest {
	using CurrencyNamer for Currency;
	using CurrencyNamer for bytes32;
	using Math for uint256;
	using PercentageMath for uint256;
	using PositionMath for uint256;
	using PositionUtils for LeveragedPosition;
	using WadRayMath for uint256;

	struct PositionState {
		uint256 totalCollateral;
		uint256 totalCollateralInBase;
		uint256 totalDebt;
		uint256 totalDebtInBase;
		uint256 availableLiquidity;
		uint256 availableLiquidityInBase;
		uint256 availableBorrows;
		uint256 availableBorrowsInBase;
		uint256 principal;
		uint256 principalInBase;
		uint256 ltv;
		uint256 collateralUsage;
		uint256 healthFactor;
		uint256 leverage;
		uint256 collateralFactor;
		uint256 liquidationFactor;
		uint256 collateralPrice;
		uint256 liabilityPrice;
		bytes path;
	}

	string internal protocolKey;
	bytes32 internal protocolId;

	Routes internal routes;

	Configurator internal configurator;
	PositionDeployer internal deployerImpl;
	PositionDeployer internal deployer;

	PositionDescriptor internal descriptorImpl;
	PositionDescriptor internal descriptor;

	LeveragedPosition internal position;

	Currency[] internal collateralAssets;
	Currency[] internal liabilityAssets;

	Currency internal collateralAsset;
	Currency internal liabilityAsset;

	uint256 internal collateralScale;
	uint256 internal liabilityScale;

	function setUp() public virtual override {
		super.setUp();

		routes = new Routes();

		label(address(configurator = new Configurator(address(this))), "Configurator");

		configurator.setPositionDeployerImpl(address(new PositionDeployer()));
		configurator.setPositionDescriptorImpl(address(new PositionDescriptor()));

		label(address(deployer = PositionDeployer(configurator.getPositionDeployer())), "PositionDeployer");
		label(address(descriptor = PositionDescriptor(configurator.getPositionDescriptor())), "PositionDescriptor");

		(collateralAsset, liabilityAsset) = randomReserves();

		collateralScale = 10 ** collateralAsset.decimals();
		liabilityScale = 10 ** liabilityAsset.decimals();
	}

	function setProtocol(string memory key, bytes32 id) internal virtual {
		protocolKey = key;
		protocolId = id;
	}

	function test_sweep() public virtual {
		assertEq(WSTETH.balanceOfSelf(), 0);
		assertEq(USDC.balanceOfSelf(), 0);

		uint256 wstethAmount = 10 ether;
		uint256 usdcAmount = 10000 * 1e6;

		deal(WSTETH, address(position), wstethAmount);
		deal(USDC, address(position), usdcAmount);

		revertToState();

		position.sweep(WSTETH);
		position.sweep(USDC);

		assertEq(WSTETH.balanceOfSelf(), wstethAmount, "!wstETH");
		assertEq(USDC.balanceOfSelf(), usdcAmount, "!USDC");

		revertToState();

		vm.startPrank(vm.addr(encodePrivateKey("InvalidOwner")));

		vm.expectRevert(Errors.Unauthorized.selector);
		position.sweep(WSTETH);

		vm.expectRevert(Errors.Unauthorized.selector);
		position.sweep(USDC);

		vm.stopPrank();
	}

	function executeIncreaseLiquidity(
		uint256 amountToDeposit,
		bytes memory path
	) internal virtual impersonate(position.OWNER()) returns (PositionState memory state) {
		vm.assume(amountToDeposit != 0);
		vm.assume(path.length != 0);
		state.path = path;

		ILeveragedPosition.IncreaseLiquidityParams memory params;

		{
			(, , state.ltv) = position.ltvBounds();
			vm.assume(state.ltv != 0);

			state.collateralFactor = position.getCollateralFactor();
			state.liquidationFactor = position.getLiquidationFactor();

			deal(collateralAsset, position.OWNER(), amountToDeposit);

			params = ILeveragedPosition.IncreaseLiquidityParams({amountToDeposit: amountToDeposit, path: state.path});
		}

		position.increaseLiquidity(params);

		{
			state.collateralPrice = position.getCollateralPrice();
			state.liabilityPrice = position.getLiabilityPrice();

			state.totalCollateral = position.getCollateralBalance();
			state.totalCollateralInBase = state.totalCollateral.convertToBase(state.collateralPrice, collateralScale);

			state.totalDebt = position.getLiabilityBalance();
			state.totalDebtInBase = state.totalDebt.convertToBase(state.liabilityPrice, liabilityScale);

			state.availableLiquidity = state.totalCollateral.percentMul(state.collateralFactor);
			state.availableLiquidityInBase = state.availableLiquidity.convertToBase(
				state.collateralPrice,
				collateralScale
			);

			state.availableBorrowsInBase = state.availableLiquidityInBase - state.totalDebtInBase;
			state.availableBorrows = state.availableBorrowsInBase.convertFromBase(state.liabilityPrice, liabilityScale);

			state.principalInBase = state.totalCollateralInBase - state.totalDebtInBase;
			state.principal = state.principalInBase.convertFromBase(state.collateralPrice, collateralScale);

			state.leverage = state.totalCollateralInBase.percentDiv(state.principalInBase);
			state.healthFactor = MAX_UINT256;

			if (state.totalDebtInBase != 0) {
				state.collateralUsage = state.totalDebtInBase.percentDiv(state.availableLiquidityInBase);

				state.healthFactor = state.totalCollateralInBase.percentMul(state.liquidationFactor).wadDiv(
					state.totalDebtInBase
				);
			}
		}
	}

	function executeDecreaseLiquidity(
		uint256 amountToWithdraw,
		bool shouldClaim,
		bytes memory path
	) internal virtual impersonate(position.OWNER()) returns (PositionState memory state) {
		vm.assume(path.length != 0);
		state.path = path;

		ILeveragedPosition.DecreaseLiquidityParams memory params;

		{
			(, , state.ltv) = position.ltvBounds();
			state.collateralFactor = position.getCollateralFactor();
			state.liquidationFactor = position.getLiquidationFactor();

			state.collateralPrice = position.getCollateralPrice();
			state.liabilityPrice = position.getLiabilityPrice();

			uint256 totalCollateral = position.getCollateralBalance();
			uint256 totalDebt = position.getLiabilityBalance();

			uint256 principal = totalCollateral.computePrincipal(
				totalDebt,
				state.collateralPrice,
				state.liabilityPrice,
				collateralScale,
				liabilityScale
			);

			if (amountToWithdraw == 0) amountToWithdraw = principal;

			params = ILeveragedPosition.DecreaseLiquidityParams({
				amountToWithdraw: amountToWithdraw,
				shouldClaim: shouldClaim,
				path: state.path
			});
		}

		position.decreaseLiquidity(params);

		{
			state.totalCollateral = position.getCollateralBalance();
			state.totalCollateralInBase = state.totalCollateral.convertToBase(state.collateralPrice, collateralScale);

			state.totalDebt = position.getLiabilityBalance();
			state.totalDebtInBase = state.totalDebt.convertToBase(state.liabilityPrice, liabilityScale);

			state.availableLiquidity = state.totalCollateral.percentMul(state.collateralFactor);
			state.availableLiquidityInBase = state.availableLiquidity.convertToBase(
				state.collateralPrice,
				collateralScale
			);

			state.availableBorrowsInBase = state.availableLiquidityInBase - state.totalDebtInBase;
			state.availableBorrows = state.availableBorrowsInBase.convertFromBase(state.liabilityPrice, liabilityScale);

			state.principalInBase = state.totalCollateralInBase - state.totalDebtInBase;
			state.principal = state.principalInBase.convertFromBase(state.collateralPrice, collateralScale);

			state.leverage = state.totalCollateralInBase.percentDiv(state.principalInBase);
			state.healthFactor = MAX_UINT256;

			if (state.totalDebtInBase != 0) {
				state.collateralUsage = state.totalDebtInBase.percentDiv(state.availableLiquidityInBase);

				state.healthFactor = state.totalCollateralInBase.percentMul(state.liquidationFactor).wadDiv(
					state.totalDebtInBase
				);
			}
		}
	}

	function deployPosition(
		bytes32 id,
		uint256 ltvUpperBound,
		uint256 ltvLowerBound,
		address owner
	) internal virtual impersonate(owner) returns (LeveragedPosition pos) {
		ILender lender = ILender(configurator.getAddress(id));

		if (ltvUpperBound == 0 || ltvLowerBound == 0) {
			ltvLowerBound = (ltvUpperBound = 8000) - 1000;
		}

		vm.assume(ltvUpperBound < BPS);
		vm.assume(ltvLowerBound < ltvUpperBound);

		string memory ticker = string.concat(
			id.bytes32ToString(),
			" ",
			collateralAsset.symbol(),
			"/",
			liabilityAsset.symbol()
		);

		bytes memory params = abi.encode(
			type(LeveragedPosition).creationCode,
			abi.encode(lender, collateralAsset, liabilityAsset)
		);

		label(address(pos = LeveragedPosition(deployer.deployPosition(params))), ticker);

		pos.setLtvBounds(ltvUpperBound, ltvLowerBound);

		collateralAsset.approve(address(pos), MAX_UINT256);
		liabilityAsset.approve(address(pos), MAX_UINT256);
	}

	function deployAaveV3Lender(
		bytes32 id,
		address pool,
		address oracle,
		address rewardsController
	) internal virtual returns (AaveV3Lender lender) {
		configurator.setAddress(id, address(lender = new AaveV3Lender(id, pool, oracle, rewardsController)));

		label(address(lender), id.bytes32ToString());
	}

	function deployCompoundV3Lender(
		bytes32 id,
		address comet,
		address feed,
		address rewardsController
	) internal virtual returns (CompoundV3Lender lender) {
		configurator.setAddress(id, address(lender = new CompoundV3Lender(id, comet, feed, rewardsController)));

		label(address(lender), id.bytes32ToString());
	}

	function randomReserves() internal virtual returns (Currency collateral, Currency liability) {
		collateral = randomCollateral();
		liability = randomLiability(collateral);
	}

	function randomCollateral(Currency exception) internal virtual returns (Currency asset) {
		return randomAsset(collateralAssets, exception);
	}

	function randomCollateral() internal virtual returns (Currency) {
		return randomAsset(collateralAssets);
	}

	function randomLiability(Currency exception) internal virtual returns (Currency asset) {
		return randomAsset(liabilityAssets, exception);
	}

	function randomLiability() internal virtual returns (Currency) {
		return randomAsset(liabilityAssets);
	}

	function minCollateralFactor() internal pure virtual returns (uint256) {
		return 1000;
	}

	function minLiquidity() internal pure virtual returns (uint256) {
		return 1000000 * 1e8;
	}

	function PROTOCOL_KEY() internal pure virtual returns (string memory);

	function PROTOCOL_ID() internal pure virtual returns (bytes32);

	function setUpMarkets(string memory key) internal virtual;

	function setPath(uint256 amountToDeposit, bool reverse) internal virtual returns (bytes memory path);

	function setSupplyCap(Currency currency, uint256 supplyCap) internal virtual;

	function setBorrowCap(Currency currency, uint256 borrowCap) internal virtual;
}
