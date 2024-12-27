// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

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

import {MockLeveragedPosition} from "test/mocks/MockLeveragedPosition.sol";
import {PositionUtils} from "test/shared/utils/PositionUtils.sol";
import {Routes} from "test/shared/utils/Routes.sol";
import {BaseTest} from "test/shared/BaseTest.sol";

abstract contract PositionTest is BaseTest {
	using CurrencyNamer for Currency;
	using CurrencyNamer for bytes32;
	using Math for uint256;
	using PercentageMath for uint256;
	using PositionMath for uint256;
	using PositionUtils for MockLeveragedPosition;
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

	bytes32 internal constant CACHED_STATES_SLOT = 0xbccfadcee7b0732cf801848fc4efcf23fc7b691eead903e5750a9a818b768920;

	bytes32 internal constant ACTION_KEY = "ACTION";
	bytes32 internal constant COLLATERAL_KEY = "COLLATERAL";
	bytes32 internal constant LIABILITY_KEY = "LIABILITY";

	bytes32 internal constant INCREASE_LIQUIDITY_ACTION = "INCREASE_LIQUIDITY";
	bytes32 internal constant DECREASE_LIQUIDITY_ACTION = "DECREASE_LIQUIDITY";

	uint256 internal constant PRICE_UNIT = 8;
	uint256 internal constant PRINCIPAL_IN_BASE = 10000 * (10 ** PRICE_UNIT);

	string internal protocolKey;
	bytes32 internal protocolId;

	Routes internal routes;

	Configurator internal configurator;
	PositionDeployer internal deployer;
	PositionDescriptor internal descriptor;

	MockLeveragedPosition internal position;

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
	}

	function test_increaseLiquidity_revertsIfNotAuthorized() public virtual {
		position = deployPosition(0, 0, address(this));

		ILeveragedPosition.IncreaseLiquidityParams memory params = ILeveragedPosition.IncreaseLiquidityParams({
			amountToDeposit: 10 ether,
			path: emptyData()
		});

		vm.prank(vm.addr(encodePrivateKey("InvalidOwner")));
		vm.expectRevert(Errors.Unauthorized.selector);
		position.increaseLiquidity(params);
	}

	function test_increaseLiquidity_revertsIfActionSlotIsNotEmpty() public virtual {
		position = deployPosition(0, 0, address(this));

		position.setCachedStorage(ACTION_KEY, INCREASE_LIQUIDITY_ACTION);
		assertEq(position.getCachedStorage(ACTION_KEY), INCREASE_LIQUIDITY_ACTION);

		ILeveragedPosition.IncreaseLiquidityParams memory params = ILeveragedPosition.IncreaseLiquidityParams({
			amountToDeposit: 10 ether,
			path: emptyData()
		});

		vm.expectRevert(Errors.SlotNotEmpty.selector);
		position.increaseLiquidity(params);
	}

	function test_increaseLiquidity_revertsWithInvalidPath() public virtual {
		position = deployPosition(0, 0, address(this));

		ILeveragedPosition.IncreaseLiquidityParams memory params = ILeveragedPosition.IncreaseLiquidityParams({
			amountToDeposit: 10 ether,
			path: emptyData()
		});

		vm.expectRevert(Errors.InvalidPathLength.selector);
		position.increaseLiquidity(params);

		params.path = abi.encodePacked(liabilityAsset, uint24(3000), collateralAsset);

		vm.expectRevert(Errors.InvalidCurrencyFirst.selector);
		position.increaseLiquidity(params);

		params.path = abi.encodePacked(collateralAsset, uint24(3000), collateralAsset);

		vm.expectRevert(Errors.InvalidCurrencyLast.selector);
		position.increaseLiquidity(params);
	}

	function test_increaseLiquidity_revertsWithInvalidCollateralAsset() public virtual {
		position = deployPosition(0, 0, address(this));

		uint256 amountToDeposit = 10 * collateralScale;
		deal(collateralAsset, address(this), amountToDeposit);

		ILeveragedPosition.IncreaseLiquidityParams memory params = ILeveragedPosition.IncreaseLiquidityParams({
			amountToDeposit: amountToDeposit,
			path: abi.encodePacked(collateralAsset, uint24(3000), liabilityAsset)
		});

		vm.expectRevert(Errors.InvalidCollateralAsset.selector);
		position.increaseLiquidity(params);
	}

	function test_increaseLiquidity_revertsWithInsufficientPrincipal() public virtual {
		position = deployPosition(0, 0, address(this));

		ILeveragedPosition.IncreaseLiquidityParams memory params = ILeveragedPosition.IncreaseLiquidityParams({
			amountToDeposit: 0,
			path: emptyData()
		});

		vm.expectRevert(Errors.InsufficientPrincipal.selector);
		position.increaseLiquidity(params);
	}

	function test_increaseLiquidity() public virtual {
		position = deployPosition(0, 0, address(this));

		uint256 amountToDeposit = PRINCIPAL_IN_BASE.convertFromBase(position.getCollateralPrice(), collateralScale);

		(, , uint16 loanToValue) = position.ltvBounds();
		uint256 amountOut = amountToDeposit.percentDiv(BPS - loanToValue) - amountToDeposit;
		bytes memory path = setPath(amountOut, false);

		PositionState memory state = executeIncreaseLiquidity(amountToDeposit, path);

		assertGt(state.totalCollateralInBase, 0, "!totalCollateralInBase");
		assertGt(state.totalDebtInBase, 0, "!totalDebtInBase");
		assertGt(state.availableBorrowsInBase, 0, "!availableBorrowsInBase");
		assertCloseTo(state.collateralUsage, state.ltv, "!collateralUsage");
	}

	function test_decreaseLiquidity_revertsIfNotAuthorized() public virtual {
		position = deployPosition(0, 0, address(this));

		ILeveragedPosition.DecreaseLiquidityParams memory params = ILeveragedPosition.DecreaseLiquidityParams({
			amountToWithdraw: 10 ether,
			shouldClaim: true,
			path: emptyData()
		});

		vm.prank(vm.addr(encodePrivateKey("InvalidOwner")));
		vm.expectRevert(Errors.Unauthorized.selector);
		position.decreaseLiquidity(params);
	}

	function test_decreaseLiquidity_revertsIfActionSlotIsNotEmpty() public virtual {
		position = deployPosition(0, 0, address(this));

		position.setCachedStorage(ACTION_KEY, DECREASE_LIQUIDITY_ACTION);
		assertEq(position.getCachedStorage(ACTION_KEY), DECREASE_LIQUIDITY_ACTION);

		ILeveragedPosition.DecreaseLiquidityParams memory params = ILeveragedPosition.DecreaseLiquidityParams({
			amountToWithdraw: 0,
			shouldClaim: true,
			path: emptyData()
		});

		vm.expectRevert(Errors.SlotNotEmpty.selector);
		position.decreaseLiquidity(params);
	}

	function test_decreaseLiquidity_revertsWithInvalidPath() public virtual {
		position = deployPosition(0, 0, address(this));

		ILeveragedPosition.DecreaseLiquidityParams memory params = ILeveragedPosition.DecreaseLiquidityParams({
			amountToWithdraw: 10 ether,
			shouldClaim: true,
			path: emptyData()
		});

		vm.expectRevert(Errors.InvalidPathLength.selector);
		position.decreaseLiquidity(params);

		params.path = abi.encodePacked(collateralAsset, uint24(3000), liabilityAsset);

		vm.expectRevert(Errors.InvalidCurrencyFirst.selector);
		position.decreaseLiquidity(params);

		params.path = abi.encodePacked(liabilityAsset, uint24(3000), liabilityAsset);

		vm.expectRevert(Errors.InvalidCurrencyLast.selector);
		position.decreaseLiquidity(params);
	}

	function test_decreaseLiquidity_revertsWithInsufficientLiquidity() public virtual {
		position = deployPosition(0, 0, address(this));

		ILeveragedPosition.DecreaseLiquidityParams memory params = ILeveragedPosition.DecreaseLiquidityParams({
			amountToWithdraw: 10 ether,
			shouldClaim: true,
			path: abi.encodePacked(liabilityAsset, uint24(3000), collateralAsset)
		});

		vm.expectRevert(Errors.InsufficientLiquidity.selector);
		position.decreaseLiquidity(params);
	}

	function test_decreaseLiquidity() public virtual {
		position = deployPosition(0, 0, address(this));

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

		assertEq(collateralAsset.balanceOfSelf(), amountToWithdraw, "!amountToWithdraw");
		assertGt(increaseState.principal, decreaseState.principal, "!principal");
		assertGt(increaseState.totalCollateral, decreaseState.totalCollateral, "!totalCollateral");
		assertGt(increaseState.totalDebt, decreaseState.totalDebt, "!totalDebt");
		assertGt(increaseState.availableLiquidity, decreaseState.availableLiquidity, "!availableLiquidity");
		assertGt(increaseState.availableBorrows, decreaseState.availableBorrows, "!availableBorrows");
		assertEq(increaseState.ltv, decreaseState.ltv, "!ltv");
		assertCloseTo(increaseState.collateralUsage, decreaseState.collateralUsage, "!collateralUsage");
	}

	function test_sweep() public virtual {
		position = deployPosition(0, 0, address(this));

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

		deal(collateralAsset, position.OWNER(), amountToDeposit);

		ILeveragedPosition.IncreaseLiquidityParams memory params = ILeveragedPosition.IncreaseLiquidityParams({
			amountToDeposit: amountToDeposit,
			path: path
		});

		position.increaseLiquidity(params);

		state = setPositionState(path);
	}

	function executeDecreaseLiquidity(
		uint256 amountToWithdraw,
		bool shouldClaim,
		bytes memory path
	) internal virtual impersonate(position.OWNER()) returns (PositionState memory state) {
		uint256 totalCollateral = position.getCollateralBalance();
		uint256 totalDebt = position.getLiabilityBalance();
		uint256 principal = totalCollateral.computePrincipal(
			totalDebt,
			position.getCollateralPrice(),
			position.getLiabilityPrice(),
			collateralScale,
			liabilityScale
		);

		if (amountToWithdraw == 0) amountToWithdraw = principal;

		ILeveragedPosition.DecreaseLiquidityParams memory params = ILeveragedPosition.DecreaseLiquidityParams({
			amountToWithdraw: amountToWithdraw,
			shouldClaim: shouldClaim,
			path: path
		});

		position.decreaseLiquidity(params);

		state = setPositionState(path);
	}

	function setPositionState(bytes memory path) internal view virtual returns (PositionState memory state) {
		vm.assume(path.length != 0);
		state.path = path;

		(, , state.ltv) = position.ltvBounds();
		state.collateralFactor = position.getCollateralFactor();
		state.liquidationFactor = position.getLiquidationFactor();

		state.collateralPrice = position.getCollateralPrice();
		state.liabilityPrice = position.getLiabilityPrice();

		state.totalCollateral = position.getCollateralBalance();
		state.totalCollateralInBase = state.totalCollateral.convertToBase(state.collateralPrice, collateralScale);

		state.totalDebt = position.getLiabilityBalance();
		state.totalDebtInBase = state.totalDebt.convertToBase(state.liabilityPrice, liabilityScale);

		state.availableLiquidity = state.totalCollateral.percentMul(state.collateralFactor);
		state.availableLiquidityInBase = state.availableLiquidity.convertToBase(state.collateralPrice, collateralScale);

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

	function deployPosition(
		uint256 ltvUpperBound,
		uint256 ltvLowerBound,
		address owner
	) internal virtual impersonate(owner) returns (MockLeveragedPosition pos) {
		ILender lender = ILender(configurator.getAddress(protocolId));

		if (ltvUpperBound == 0 || ltvLowerBound == 0) {
			ltvLowerBound = (ltvUpperBound = 8000) - 1000;
		}

		vm.assume(ltvUpperBound < BPS);
		vm.assume(ltvLowerBound < ltvUpperBound);

		bytes memory params = abi.encode(
			type(MockLeveragedPosition).creationCode,
			abi.encode(lender, collateralAsset, liabilityAsset)
		);

		label(
			address(pos = MockLeveragedPosition(deployer.deployPosition(params))),
			descriptor.parseTicker(lender, collateralAsset, liabilityAsset)
		);

		pos.setLtvBounds(ltvUpperBound, ltvLowerBound);

		collateralAsset.approve(address(pos), MAX_UINT256);
		liabilityAsset.approve(address(pos), MAX_UINT256);
	}

	function deployPosition(
		bytes32 id,
		uint256 ltvUpperBound,
		uint256 ltvLowerBound,
		address owner
	) internal virtual impersonate(owner) returns (MockLeveragedPosition pos) {
		ILender lender = ILender(configurator.getAddress(id));

		if (ltvUpperBound == 0 || ltvLowerBound == 0) {
			ltvLowerBound = (ltvUpperBound = 8000) - 1000;
		}

		vm.assume(ltvUpperBound < BPS);
		vm.assume(ltvLowerBound < ltvUpperBound);

		bytes memory params = abi.encode(
			type(MockLeveragedPosition).creationCode,
			abi.encode(lender, collateralAsset, liabilityAsset)
		);

		label(
			address(pos = MockLeveragedPosition(deployer.deployPosition(params))),
			descriptor.parseTicker(lender, collateralAsset, liabilityAsset)
		);

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

	function setProtocol(string memory key, bytes32 id) internal virtual {
		protocolKey = key;
		protocolId = id;
	}

	function setPath(uint256 amountOut, bool reverse) internal virtual returns (bytes memory path) {
		(path, ) = !reverse
			? routes.findRouteForExactOut(liabilityAsset, collateralAsset, amountOut)
			: routes.findRouteForExactOut(collateralAsset, liabilityAsset, amountOut);
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

	function setUpMarkets(string memory key) internal virtual;
}
