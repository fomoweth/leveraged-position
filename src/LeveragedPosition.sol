// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILeveragedPosition} from "src/interfaces/ILeveragedPosition.sol";
import {ILender} from "src/interfaces/ILender.sol";
import {MASK_160_BITS, MASK_128_BITS, MASK_104_BITS, MASK_80_BITS, MASK_40_BITS, MASK_16_BITS, MASK_8_BITS} from "src/libraries/BitMasks.sol";
import {Errors} from "src/libraries/Errors.sol";
import {Math} from "src/libraries/Math.sol";
import {Path} from "src/libraries/Path.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {PositionMath} from "src/libraries/PositionMath.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {StorageSlot} from "src/libraries/StorageSlot.sol";
import {TypeConversion} from "src/libraries/TypeConversion.sol";
import {Currency} from "src/types/Currency.sol";
import {Authority} from "src/base/Authority.sol";
import {Chain} from "src/base/Chain.sol";
import {Dispatcher} from "src/base/Dispatcher.sol";
import {V3Swap} from "src/base/V3Swap.sol";

/// @title LeveragedPosition

contract LeveragedPosition is ILeveragedPosition, Authority, Dispatcher, V3Swap {
	using Math for uint256;
	using Path for bytes;
	using PercentageMath for uint256;
	using PositionMath for uint256;
	using SafeCast for uint256;
	using StorageSlot for bytes32;
	using TypeConversion for bytes32;
	using TypeConversion for uint256;
	using TypeConversion for int256;

	/// bytes32(uint256(keccak256("CachedStates")) - 1)
	bytes32 internal constant CACHED_STATES_SLOT = 0xbccfadcee7b0732cf801848fc4efcf23fc7b691eead903e5750a9a818b768920;

	/// bytes32(uint256(keccak256("Checkpoints")) - 1)
	bytes32 internal constant CHECKPOINTS_SLOT = 0xeded99094b44ca9eb47e05613fb3034bde089727218b718bf410858d557d0649;

	/// bytes32(uint256(keccak256("Liquidity")) - 1)
	bytes32 internal constant LIQUIDITY_SLOT = 0xf635637ba62fd05a8c192160221386e8a7a4f08458b93e1a9885a356979e4200;

	/// bytes32(uint256(keccak256("LoanToValueBounds")) - 1)
	bytes32 internal constant LTV_BOUNDS_SLOT = 0xf44fb122107512ba249743c2468120cbe34f13a1b438b749d63480d1c4312fb6;

	/// bytes32(uint256(keccak256("Principal")) - 1)
	bytes32 internal constant PRINCIPAL_SLOT = 0x6d2a34b0387139aa2bb1b3006d0e90a0e236e2de0856f51e29948c01ab963ccd;

	bytes32 internal constant ACTION_KEY = "ACTION";
	bytes32 internal constant COLLATERAL_KEY = "COLLATERAL";
	bytes32 internal constant LIABILITY_KEY = "LIABILITY";

	bytes32 internal constant INCREASE_LIQUIDITY_ACTION = "INCREASE_LIQUIDITY";
	bytes32 internal constant DECREASE_LIQUIDITY_ACTION = "DECREASE_LIQUIDITY";

	uint8 internal constant COLLATERAL_SIDE = 1;
	uint8 internal constant LIABILITY_SIDE = 2;

	uint64 internal immutable COLLATERAL_SCALE;
	uint64 internal immutable LIABILITY_SCALE;

	uint256 public constant REVISION = 0x01;

	address public immutable OWNER;
	address public immutable LENDER;
	Currency public immutable COLLATERAL_ASSET;
	Currency public immutable LIABILITY_ASSET;

	constructor(address _owner, address _lender, Currency _collateralAsset, Currency _LIABILITY_ASSET) {
		required(!_collateralAsset.isZero(), Errors.InvalidCollateralAsset.selector);
		required(!_LIABILITY_ASSET.isZero(), Errors.InvalidLiabilityAsset.selector);
		required(_collateralAsset != _LIABILITY_ASSET, Errors.IdenticalAssets.selector);

		OWNER = verifyAddress(_owner);
		LENDER = verifyContract(_lender);
		COLLATERAL_ASSET = _collateralAsset;
		LIABILITY_ASSET = _LIABILITY_ASSET;
		COLLATERAL_SCALE = uint64(10 ** _collateralAsset.decimals());
		LIABILITY_SCALE = uint64(10 ** _LIABILITY_ASSET.decimals());
	}

	function setLtvBounds(uint256 upperBound, uint256 lowerBound) external authorized {
		required(upperBound < PercentageMath.BPS, Errors.InvalidUpperBound.selector);
		required(lowerBound < upperBound || (lowerBound == 0 && upperBound == 0), Errors.InvalidLowerBound.selector);

		uint256 medianBound = upperBound.average(lowerBound);

		assembly ("memory-safe") {
			sstore(
				LTV_BOUNDS_SLOT,
				or(
					add(shl(32, and(MASK_16_BITS, medianBound)), shl(16, and(MASK_16_BITS, lowerBound))),
					and(MASK_16_BITS, upperBound)
				)
			)
		}

		emit LtvBoundsSet(upperBound, lowerBound, medianBound);
	}

	function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable authorized {
		// verify that the action slot is empty then cache increase liquidity action;
		// prevents the reentrancy and will be used in the swap callback
		bytes32 actionSlot = cache(ACTION_KEY);
		required(actionSlot.isEmpty(), Errors.SlotNotEmpty.selector);

		actionSlot.tstore(INCREASE_LIQUIDITY_ACTION);

		required(params.amountToDeposit != 0, Errors.InsufficientPrincipalAmount.selector);

		params.path.verify(COLLATERAL_ASSET, LIABILITY_ASSET);

		uint256 collateralFactor = getCollateralFactor();
		required(collateralFactor != 0, Errors.InvalidCollateralAsset.selector);

		uint256 ltv = collateralFactor.percentMul(LTV_BOUNDS_SLOT.sload().asUint256().shiftRight(32));

		// amount of collateral to be supplied into the lending pool
		uint256 amountToSupply = params.amountToDeposit.percentDiv(PercentageMath.BPS.sub(ltv));
		// amount of collateral to be received from the swap pool
		uint256 amountToFlash = amountToSupply.sub(params.amountToDeposit);

		COLLATERAL_ASSET.transferFrom(msg.sender, address(this), params.amountToDeposit);
		updatePrincipal(params.amountToDeposit.toInt256());

		if (amountToFlash != 0) {
			// amount of debt to borrow from the lending pool
			uint256 amountToBorrow = quoteExactOutput(amountToFlash, params.path);
			required(amountToBorrow <= getAvailableLiquidity(), Errors.InsufficientPoolLiquidity.selector);

			uint256 availableLiquidityInBase = getPositionCollateral()
				.add(amountToSupply)
				.percentMul(collateralFactor)
				.convertToBase(getPrice(COLLATERAL_ASSET), COLLATERAL_SCALE);

			uint256 totalDebtInBase = getPositionLiability().add(amountToBorrow).convertToBase(
				getPrice(LIABILITY_ASSET),
				LIABILITY_SCALE
			);

			required(totalDebtInBase < availableLiquidityInBase, Errors.InsufficientCollateral.selector);

			cache(COLLATERAL_KEY).tstore(amountToSupply.asBytes32());
			cache(LIABILITY_KEY).tstore(amountToBorrow.asBytes32());

			exactOutputInternal(amountToFlash, params.path);

			cache(COLLATERAL_KEY).tclear();
			cache(LIABILITY_KEY).tclear();
		} else {
			supplyInternal(amountToSupply);
		}

		setCheckpoint(COLLATERAL_ASSET, getRatio(COLLATERAL_ASSET));
		setCheckpoint(LIABILITY_ASSET, getRatio(LIABILITY_ASSET));

		actionSlot.tclear();
	}

	function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable authorized {
		// verify that the action slot is empty then cache decrease liquidity action;
		// prevents the reentrancy and will be used in the swap callback
		bytes32 actionSlot = cache(ACTION_KEY);
		required(actionSlot.isEmpty(), Errors.SlotNotEmpty.selector);

		actionSlot.tstore(DECREASE_LIQUIDITY_ACTION);

		params.path.verify(LIABILITY_ASSET, COLLATERAL_ASSET);

		(uint256 totalCollateral, uint256 totalDebt) = (getPositionCollateral(), getPositionLiability());
		required(totalCollateral != 0, Errors.InsufficientLiquidity.selector);

		// amount of collateral required to be redeemed from the lending pool
		uint256 amountToRedeem;
		// amount of collateral to be withdrawn from principal at the end of the iteration
		uint256 amountToWithdraw;

		if (totalDebt != 0) {
			uint256 ltv = getCollateralFactor().percentMul(LTV_BOUNDS_SLOT.sload().asUint256().shiftRight(32));

			uint256 collateralPrice = getPrice(COLLATERAL_ASSET);
			uint256 liabilityPrice = getPrice(LIABILITY_ASSET);

			uint256 amountPrincipal = totalCollateral.computePrincipal(
				totalDebt,
				collateralPrice,
				liabilityPrice,
				COLLATERAL_SCALE,
				LIABILITY_SCALE
			);

			amountToWithdraw = Math.ternary(ltv != 0, params.amountToWithdraw.min(amountPrincipal), amountPrincipal);

			amountPrincipal = amountPrincipal.sub(amountToWithdraw);

			// amount of liability asset to be used for repaying the debt
			uint256 amountToFlash;

			if (amountPrincipal != 0) {
				// compute the amount of collateral to be redeemed
				uint256 collateralDelta = totalCollateral.zeroFloorSub(
					amountPrincipal.percentDiv(PercentageMath.BPS.sub(ltv))
				);

				amountToFlash = collateralDelta
					.sub(amountToWithdraw)
					.convertToBase(collateralPrice, COLLATERAL_SCALE)
					.convertFromBase(liabilityPrice, LIABILITY_SCALE);

				amountToRedeem = quoteExactOutput(amountToFlash, params.path).add(amountToWithdraw);
			} else {
				// repay all debt and redeem all collateral
				amountToFlash = totalDebt;
				amountToRedeem = totalCollateral;
			}

			cache(LIABILITY_KEY).tstore(amountToFlash.asBytes32());
			cache(COLLATERAL_KEY).tstore(amountToRedeem.asBytes32());

			exactOutputInternal(amountToFlash, params.path);

			cache(LIABILITY_KEY).tclear();
			cache(COLLATERAL_KEY).tclear();
		} else {
			// if the position is debt free then redeem and withdraw all collaterals
			amountToRedeem = amountToWithdraw = totalCollateral;
			redeemInternal(amountToRedeem);
		}

		if ((amountToWithdraw = amountToWithdraw.min(COLLATERAL_ASSET.balanceOfSelf())) != 0) {
			updatePrincipal(-amountToWithdraw.toInt256());
			COLLATERAL_ASSET.transfer(msg.sender, amountToWithdraw);
		}

		if (params.shouldClaim) claimInternal(msg.sender);

		setCheckpoint(COLLATERAL_ASSET, getRatio(COLLATERAL_ASSET));
		setCheckpoint(LIABILITY_ASSET, getRatio(LIABILITY_ASSET));

		actionSlot.tclear();
	}

	function addCollateral(uint256 amount) external payable authorized {
		COLLATERAL_ASSET.transferFrom(msg.sender, address(this), amount);
		updatePrincipal(amount.toInt256());

		supplyInternal(amount);

		setCheckpoint(COLLATERAL_ASSET, getRatio(COLLATERAL_ASSET));
	}

	function repayDebt(uint256 amount) external payable authorized {
		LIABILITY_ASSET.transferFrom(msg.sender, address(this), amount);

		repayInternal(amount);

		setCheckpoint(LIABILITY_ASSET, getRatio(LIABILITY_ASSET));
	}

	function claimRewards(address recipient) external payable authorized {
		claimInternal(recipient);
	}

	function sweep(Currency currency) external payable authorized {
		uint256 balance = currency.balanceOfSelf();
		if (balance == 0) return;

		currency.transfer(msg.sender, balance);
	}

	function handleV3SwapCallback(
		int256 amount0Delta,
		int256 amount1Delta,
		bytes calldata path
	) internal virtual override {
		required(amount0Delta != 0 || amount1Delta != 0, Errors.InvalidSwap.selector);

		// exact output swaps are executed in reverse order
		(Currency currencyOut, Currency currencyIn, ) = path.decodeFirstPool();

		(uint256 amountReceived, uint256 amountToPay) = amount0Delta < 0
			? (uint256(-amount0Delta), uint256(amount1Delta))
			: (uint256(-amount1Delta), uint256(amount0Delta));

		// determine the cached liquidity action then verify
		bytes32 actionCached = cache(ACTION_KEY).tload();
		required(isValidAction(actionCached), Errors.InvalidAction.selector);

		if (actionCached == DECREASE_LIQUIDITY_ACTION && currencyOut == LIABILITY_ASSET) {
			required(amountReceived == cache(LIABILITY_KEY).tload().asUint256(), Errors.InsufficientAmountOut.selector);
			repayInternal(amountReceived);
		}

		if (path.hasMultiplePools()) {
			exactOutputInternal(amountToPay, path.skipCurrency());
		} else {
			if (actionCached == INCREASE_LIQUIDITY_ACTION) {
				required(currencyIn == LIABILITY_ASSET, Errors.InvalidLiabilityAsset.selector);
				required(amountToPay <= cache(LIABILITY_KEY).tload().asUint256(), Errors.InsufficientAmountIn.selector);

				supplyInternal(cache(COLLATERAL_KEY).tload().asUint256());
				borrowInternal(amountToPay);
			} else {
				required(currencyIn == COLLATERAL_ASSET, Errors.InvalidCollateralAsset.selector);

				uint256 amountToRedeem = cache(COLLATERAL_KEY).tload().asUint256();
				required(amountToPay <= amountToRedeem, Errors.InsufficientAmountIn.selector);

				redeemInternal(amountToRedeem);
			}
		}

		currencyIn.transfer(msg.sender, amountToPay);
	}

	function supplyInternal(uint256 amount) internal virtual {
		bytes memory data = abi.encodeCall(ILender.supply, (COLLATERAL_ASSET, amount));
		updateLiquidity(COLLATERAL_ASSET, abi.decode(dispatch(LENDER, data), (int256)), COLLATERAL_SIDE);
	}

	function borrowInternal(uint256 amount) internal virtual {
		bytes memory data = abi.encodeCall(ILender.borrow, (LIABILITY_ASSET, amount));
		updateLiquidity(LIABILITY_ASSET, abi.decode(dispatch(LENDER, data), (int256)), LIABILITY_SIDE);
	}

	function repayInternal(uint256 amount) internal virtual {
		bytes memory data = abi.encodeCall(ILender.repay, (LIABILITY_ASSET, amount));
		updateLiquidity(LIABILITY_ASSET, abi.decode(dispatch(LENDER, data), (int256)), LIABILITY_SIDE);
	}

	function redeemInternal(uint256 amount) internal virtual {
		bytes memory data = abi.encodeCall(ILender.redeem, (COLLATERAL_ASSET, amount));
		updateLiquidity(COLLATERAL_ASSET, abi.decode(dispatch(LENDER, data), (int256)), COLLATERAL_SIDE);
	}

	function claimInternal(address recipient) internal virtual {
		dispatch(LENDER, abi.encodeCall(ILender.claim, (recipient == address(0) ? msg.sender : recipient)));
	}

	function setCheckpoint(Currency currency, uint256 state) internal virtual {
		bytes32 derivedSlot = CHECKPOINTS_SLOT.deriveMapping(currency.toId());

		// get the length of the checkpoint array then assign it to the last index
		uint256 index = derivedSlot.sload().asUint256();

		// increment the length by 1
		derivedSlot.sstore((index.add(1)).asBytes32());

		// store new element at the last index of the array
		derivedSlot.deriveArray().offset(index).sstore(state.asBytes32());

		emit CheckpointSet(currency, index, state);
	}

	function updateLiquidity(Currency currency, int256 delta, uint8 side) internal virtual {
		bytes32 derivedSlot = LIQUIDITY_SLOT.deriveMapping(currency.toId());

		assembly ("memory-safe") {
			sstore(
				derivedSlot,
				or(
					add(
						shl(248, and(MASK_8_BITS, side)),
						add(shl(208, and(MASK_40_BITS, shr(208, delta))), shl(104, and(MASK_104_BITS, shr(104, delta))))
					),
					and(MASK_104_BITS, add(signextend(12, sload(derivedSlot)), signextend(12, delta)))
				)
			)
		}

		emit LiquidityUpdated(currency, delta, side);
	}

	function updatePrincipal(int256 delta) internal virtual {
		int256 principalCurrent = principal();

		PRINCIPAL_SLOT.sstore((principalCurrent + delta).asBytes32());

		emit PrincipalUpdated(principalCurrent, delta);
	}

	function checkpointsLengthOf(Currency currency) public view virtual returns (uint256) {
		return CHECKPOINTS_SLOT.deriveMapping(currency.toId()).sload().asUint256();
	}

	function checkpointOf(
		Currency currency,
		uint256 index
	) public view virtual returns (uint128 ratio, uint80 roundId, uint40 updatedAt) {
		bytes32 state = CHECKPOINTS_SLOT.deriveMapping(currency.toId()).deriveArray().offset(index).sload();

		assembly ("memory-safe") {
			ratio := and(MASK_128_BITS, state)
			roundId := and(MASK_80_BITS, shr(128, state))
			updatedAt := and(MASK_40_BITS, shr(208, state))
		}
	}

	function liquidityOf(
		Currency currency
	) public view virtual returns (int104 liquidity, uint104 reserveIndex, uint40 accrualTime, uint8 side) {
		bytes32 state = LIQUIDITY_SLOT.deriveMapping(currency.toId()).sload();

		assembly ("memory-safe") {
			liquidity := signextend(12, state)
			reserveIndex := and(MASK_104_BITS, shr(104, state))
			accrualTime := and(MASK_40_BITS, shr(208, state))
			side := and(MASK_8_BITS, shr(248, state))
		}
	}

	function ltvBounds() public view virtual returns (uint16 upperBound, uint16 lowerBound, uint16 medianBound) {
		assembly ("memory-safe") {
			let bounds := sload(LTV_BOUNDS_SLOT)
			upperBound := and(MASK_16_BITS, bounds)
			lowerBound := and(MASK_16_BITS, shr(16, bounds))
			medianBound := and(MASK_16_BITS, shr(32, bounds))
		}
	}

	function principal() public view returns (int256) {
		return PRINCIPAL_SLOT.sload().asInt256();
	}

	function getPositionCollateral() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getAccountCollateral, (COLLATERAL_ASSET, address(this)));
		return abi.decode(fetch(LENDER, data), (uint256));
	}

	function getPositionLiability() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getAccountLiability, (LIABILITY_ASSET, address(this)));
		return abi.decode(fetch(LENDER, data), (uint256));
	}

	function getAvailableLiquidity() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getAvailableLiquidity, (LIABILITY_ASSET));
		return abi.decode(fetch(LENDER, data), (uint256));
	}

	function getCollateralFactor() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getCollateralFactor, (COLLATERAL_ASSET));
		return abi.decode(fetch(LENDER, data), (uint256));
	}

	function getLiquidationFactor() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getLiquidationFactor, (COLLATERAL_ASSET));
		return abi.decode(fetch(LENDER, data), (uint256));
	}

	function getPrice(Currency currency) internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getPrice, (currency));
		return abi.decode(fetch(LENDER, data), (uint256));
	}

	function getRatio(Currency currency) internal view virtual returns (uint256) {
		return abi.decode(fetch(LENDER, abi.encodeCall(ILender.getRatio, (currency))), (uint256));
	}

	function isAuthorized(address account) internal view virtual override returns (bool) {
		return account == OWNER;
	}

	function isValidAction(bytes32 action) internal view virtual returns (bool) {
		return action == INCREASE_LIQUIDITY_ACTION || action == DECREASE_LIQUIDITY_ACTION;
	}

	function cache(bytes32 key) internal pure virtual returns (bytes32) {
		return CACHED_STATES_SLOT.deriveMapping(key);
	}
}
