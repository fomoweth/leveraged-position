// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MASK_160_BITS, MASK_128_BITS, MASK_104_BITS, MASK_80_BITS, MASK_40_BITS, MASK_8_BITS} from "src/libraries/BitMasks.sol";
import {Errors} from "src/libraries/Errors.sol";
import {Math} from "src/libraries/Math.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {Currency} from "src/types/Currency.sol";
import {Lender} from "./Lender.sol";

/// @title CompoundV3Lender
/// @notice Lending adapter to invoke actions of Comet

contract CompoundV3Lender is Lender {
	using Errors for bytes4;
	using Math for uint256;
	using PercentageMath for uint256;
	using SafeCast for *;

	bytes4 internal constant SUPPLY_SELECTOR = 0xf2b9fdb8;
	bytes4 internal constant WITHDRAW_SELECTOR = 0xf3fef3a3;

	uint8 internal constant PAUSE_SUPPLY_OFFSET = 0;
	uint8 internal constant PAUSE_TRANSFER_OFFSET = 1;
	uint8 internal constant PAUSE_WITHDRAW_OFFSET = 2;
	uint8 internal constant PAUSE_ABSORB_OFFSET = 3;
	uint8 internal constant PAUSE_BUY_OFFSET = 4;

	uint64 internal constant DESCALE = 1e14;
	uint64 internal constant PRICE_SCALE = 1e8;
	uint64 internal constant FACTOR_SCALE = 1e18;
	uint64 internal constant BASE_ACCRUAL_SCALE = 1e6;
	uint64 internal constant BASE_INDEX_SCALE = 1e15;
	uint64 internal immutable BASE_SCALE;
	uint64 internal immutable ACCRUAL_DESCALE_SCALE;
	uint64 internal immutable TRACKING_INDEX_SCALE;

	Currency internal immutable BASE_CURRENCY;

	constructor(
		bytes32 _protocol,
		address _comet,
		address _basePriceFeed,
		address _rewards
	) Lender(_protocol, _comet, _basePriceFeed, _rewards) {
		BASE_CURRENCY = baseToken(_comet);
		ACCRUAL_DESCALE_SCALE = (BASE_SCALE = baseScale(_comet)) / BASE_ACCRUAL_SCALE;
		TRACKING_INDEX_SCALE = trackingIndexScale(_comet);
	}

	function supply(Currency currency, uint256 amount) external payable returns (int256) {
		approveIfNeeded(currency, POOL, amount);

		invoke(POOL, SUPPLY_SELECTOR, currency, amount);

		(uint104 baseSupplyIndex, , , , , , uint40 accrualTime, ) = totalsBasic(POOL);

		return encodeCallResult(amount.toInt104(), baseSupplyIndex, accrualTime);
	}

	function borrow(Currency currency, uint256 amount) external payable returns (int256) {
		invoke(POOL, WITHDRAW_SELECTOR, currency, amount);

		(, uint64 baseBorrowIndex, , , , , uint40 accrualTime, ) = totalsBasic(POOL);

		return encodeCallResult(-amount.toInt104(), baseBorrowIndex, accrualTime);
	}

	function repay(Currency currency, uint256 amount) external payable returns (int256) {
		approveIfNeeded(currency, POOL, amount);

		invoke(POOL, SUPPLY_SELECTOR, currency, amount);

		(, uint64 baseBorrowIndex, , , , , uint40 accrualTime, ) = totalsBasic(POOL);

		return encodeCallResult(amount.toInt104(), baseBorrowIndex, accrualTime);
	}

	function redeem(Currency currency, uint256 amount) external payable returns (int256) {
		invoke(POOL, WITHDRAW_SELECTOR, currency, amount);

		(uint64 baseSupplyIndex, , , , , , uint40 accrualTime, ) = totalsBasic(POOL);

		return encodeCallResult(-amount.toInt104(), baseSupplyIndex, accrualTime);
	}

	function invoke(address comet, bytes4 selector, Currency currency, uint256 amount) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, selector)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))
			mstore(add(ptr, 0x24), amount)

			if iszero(call(gas(), comet, 0x00, ptr, 0x44, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(ptr, 0x60))
		}
	}

	function claim(address recipient) external payable {
		claimTo(REWARDS_CONTROLLER, POOL, recipient, true);
	}

	function claimTo(address rewardsController, address comet, address recipient, bool shouldAccrue) internal {
		assembly ("memory-safe") {
			if iszero(recipient) {
				recipient := address()
			}

			let ptr := mload(0x40)

			mstore(ptr, 0x4ff85d9400000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, comet))
			mstore(add(ptr, 0x24), and(MASK_160_BITS, address()))
			mstore(add(ptr, 0x44), and(MASK_160_BITS, recipient))
			mstore(add(ptr, 0x64), and(MASK_8_BITS, shouldAccrue))

			if iszero(call(gas(), rewardsController, 0x00, ptr, 0x84, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(ptr, 0xa0))
		}
	}

	function getReservesIn(address account) public view returns (Currency[] memory reserves) {
		unchecked {
			(int104 principal, , , uint16 assetsIn, ) = userBasic(POOL, account);

			if (assetsIn != 0) {
				uint8 length = numAssets(POOL);
				uint8 count;
				uint8 offset;

				reserves = new Currency[](length + 1);

				if (principal != 0) {
					reserves[0] = BASE_CURRENCY;
					count = count + 1;
				}

				while (offset < length) {
					if (isAssetIn(assetsIn, offset)) {
						(reserves[count], , , , , , ) = getAssetInfo(POOL, offset);
						count = count + 1;
					}

					offset = offset + 1;
				}

				assembly ("memory-safe") {
					if xor(add(length, 0x01), count) {
						mstore(reserves, count)
					}
				}
			}
		}
	}

	function getReservesList() external view returns (Currency[] memory reserves) {
		unchecked {
			uint8 length = numAssets(POOL);
			uint8 offset;

			reserves = new Currency[](length);

			while (offset < length) {
				(reserves[offset], , , , , , ) = getAssetInfo(POOL, offset);
				offset = offset + 1;
			}
		}
	}

	function getRewardsList() external view returns (Currency[] memory rewardAssets) {
		rewardAssets = new Currency[](1);
		(rewardAssets[0], , , ) = rewardConfig(REWARDS_CONTROLLER, POOL);
	}

	function getAccountLiquidity(
		address account
	)
		external
		view
		returns (
			uint256 totalCollateralInBase,
			uint256 totalDebtInBase,
			uint256 availableBorrowsInBase,
			uint256 collateralUsage,
			uint256 healthFactor
		)
	{
		(, uint64 baseBorrowIndex, , , , , , ) = totalsBasic(POOL);

		(int104 principal, , , uint16 assetsIn, ) = userBasic(POOL, account);

		uint256 availableLiquidityInBase;
		uint256 liquidationThreshold;

		if (principal < 0) {
			totalDebtInBase = mulPrice(
				presentValue(uint104(-principal), baseBorrowIndex),
				getPrice(POOL, baseTokenPriceFeed(POOL)),
				PRICE_SCALE
			);
		}

		uint8 length = numAssets(POOL);

		unchecked {
			for (uint8 offset; offset < length; ++offset) {
				if (isAssetIn(assetsIn, offset)) {
					(
						Currency asset,
						address priceFeed,
						uint64 scale,
						uint64 borrowFactor,
						uint64 liquidateFactor,
						,

					) = getAssetInfo(POOL, offset);

					uint256 collateralInBase = mulPrice(
						collateralBalanceOf(POOL, asset, account),
						getPrice(POOL, priceFeed),
						scale
					);

					if (collateralInBase == 0) continue;

					totalCollateralInBase += collateralInBase;
					availableLiquidityInBase += mulFactor(collateralInBase, borrowFactor);
					liquidationThreshold += mulFactor(collateralInBase, liquidateFactor);
				}
			}
		}

		availableBorrowsInBase = availableLiquidityInBase.zeroFloorSub(totalDebtInBase);

		(collateralUsage, healthFactor) = totalDebtInBase != 0
			? (
				totalDebtInBase.percentDiv(availableLiquidityInBase),
				divFactor(totalCollateralInBase.percentMul(liquidationThreshold), totalDebtInBase)
			)
			: (uint256(0), Math.MAX_UINT256);
	}

	function getAccountCollateral(Currency currency, address account) external view returns (uint256) {
		if (!isBaseToken(currency)) return collateralBalanceOf(POOL, currency, account);

		return 0;
	}

	function getAccountLiability(Currency currency, address account) external view returns (uint256) {
		if (isBaseToken(currency)) return borrowBalanceOf(POOL, account);

		return 0;
	}

	function getAvailableLiquidity(Currency currency) external view returns (uint256) {
		if (isBaseToken(currency)) {
			int256 reserves = getReserves(POOL);
			if (reserves > 0) return uint256(reserves);
		}

		return 0;
	}

	function getAccruedRewards(
		address account
	) external view returns (Currency[] memory rewardAssets, uint256[] memory accruedRewards) {
		uint64 rescaleFactor;
		bool shouldUpscale;
		uint256 multiplier;

		rewardAssets = new Currency[](1);
		(rewardAssets[0], rescaleFactor, shouldUpscale, multiplier) = rewardConfig(REWARDS_CONTROLLER, POOL);

		uint256 claimed = rewardsClaimed(REWARDS_CONTROLLER, POOL, account);

		(, , uint64 baseTrackingAccrued, , ) = userBasicAccrued(POOL, account, 0);

		uint256 accrued = shouldUpscale ? baseTrackingAccrued * rescaleFactor : baseTrackingAccrued / rescaleFactor;

		if (multiplier != 0) accrued = mulFactor(accrued, multiplier);

		accruedRewards = new uint256[](1);
		accruedRewards[0] = accrued.zeroFloorSub(claimed);
	}

	function getCollateralFactor(Currency currency) external view returns (uint256 borrowCollateralFactor) {
		if (!isBaseToken(currency)) {
			(, , , borrowCollateralFactor, , , ) = getAssetInfoByAddress(POOL, currency);
		}
	}

	function getLiquidationFactor(Currency currency) external view returns (uint256 liquidateCollateralFactor) {
		if (!isBaseToken(currency)) {
			(, , , , liquidateCollateralFactor, , ) = getAssetInfoByAddress(POOL, currency);
		}
	}

	function getRatio(Currency currency) external view returns (uint256 ratio) {
		address priceFeed = getPriceFeed(currency);
		Errors.InvalidFeed.selector.required(priceFeed != address(0));

		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xfeaf968c00000000000000000000000000000000000000000000000000000000) // latestRoundData()

			if iszero(staticcall(gas(), priceFeed, ptr, 0x04, add(ptr, 0x20), 0xa0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			ratio := or(
				add(
					shl(208, and(MASK_40_BITS, mload(add(ptr, 0x80)))),
					shl(128, and(MASK_80_BITS, mload(add(ptr, 0x20))))
				),
				and(MASK_128_BITS, mload(add(ptr, 0x40)))
			)
		}
	}

	function getPrice(Currency currency) external view returns (uint256) {
		return getPrice(POOL, getPriceFeed(currency));
	}

	function totalsBasicAccrued(
		address comet
	)
		internal
		view
		returns (
			uint64 baseSupplyIndex,
			uint64 baseBorrowIndex,
			uint64 trackingSupplyIndex,
			uint64 trackingBorrowIndex,
			uint104 totalSupplyBase,
			uint104 totalBorrowBase,
			uint40 timeElapsed
		)
	{
		uint40 lastAccrualTime;
		uint8 pauseFlags;

		(
			baseSupplyIndex,
			baseBorrowIndex,
			trackingSupplyIndex,
			trackingBorrowIndex,
			totalSupplyBase,
			totalBorrowBase,
			lastAccrualTime,
			pauseFlags
		) = totalsBasic(comet);

		unchecked {
			if ((timeElapsed = blockTimestamp() - lastAccrualTime) != 0) {
				uint104 totalSupply = presentValue(totalSupplyBase, baseSupplyIndex);
				uint104 totalBorrow = presentValue(totalBorrowBase, baseBorrowIndex);

				if (totalSupply != 0 && totalBorrow != 0) {
					uint256 utilization = divFactor(totalBorrow, totalSupply);

					baseSupplyIndex += mulFactor(baseSupplyIndex, getSupplyRate(comet, utilization) * timeElapsed);
					baseBorrowIndex += mulFactor(baseBorrowIndex, getBorrowRate(comet, utilization) * timeElapsed);
				}

				uint104 rewardsMin = baseMinForRewards(comet);

				if (totalSupplyBase >= rewardsMin) {
					trackingSupplyIndex += divScale(
						baseTrackingSupplySpeed(comet) * timeElapsed,
						totalSupplyBase,
						BASE_SCALE
					);
				}

				if (totalBorrowBase >= rewardsMin) {
					trackingBorrowIndex += divScale(
						baseTrackingBorrowSpeed(comet) * timeElapsed,
						totalBorrowBase,
						BASE_SCALE
					);
				}
			}
		}
	}

	function userBasicAccrued(
		address comet,
		address account,
		int104 delta
	)
		internal
		view
		returns (
			int104 principal,
			uint64 baseTrackingIndex,
			uint64 baseTrackingAccrued,
			uint16 assetsIn,
			uint8 reserved
		)
	{
		(, , uint64 trackingSupplyIndex, uint64 trackingBorrowIndex, , , ) = totalsBasicAccrued(comet);

		(principal, baseTrackingIndex, baseTrackingAccrued, assetsIn, reserved) = userBasic(comet, account);

		(uint104 accruedDelta, uint64 indexDelta) = principal < 0
			? (uint104(-principal), (trackingBorrowIndex - baseTrackingIndex))
			: (uint104(principal), (trackingSupplyIndex - baseTrackingIndex));

		baseTrackingAccrued += mulScale(accruedDelta, indexDelta, TRACKING_INDEX_SCALE * ACCRUAL_DESCALE_SCALE);

		baseTrackingIndex = (principal = principal + delta) < 0 ? trackingBorrowIndex : trackingSupplyIndex;
	}

	function rewardsClaimed(
		address rewardsController,
		address comet,
		address account
	) internal view returns (uint256 claimed) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x65e1239200000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, comet))
			mstore(add(ptr, 0x24), and(MASK_160_BITS, account))

			if iszero(staticcall(gas(), rewardsController, ptr, 0x44, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			claimed := mload(0x00)
		}
	}

	function rewardConfig(
		address rewardsController,
		address comet
	) internal view returns (Currency rewardAsset, uint64 rescaleFactor, bool shouldUpscale, uint256 multiplier) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x2289b6b800000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, comet))

			if iszero(staticcall(gas(), rewardsController, ptr, 0x24, add(ptr, 0x40), 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			rewardAsset := mload(add(ptr, 0x40))
			rescaleFactor := mload(add(ptr, 0x60))
			shouldUpscale := mload(add(ptr, 0x80))

			if eq(returndatasize(), 0x80) {
				multiplier := mload(add(ptr, 0xa0))
			}
		}
	}

	function getPriceFeed(Currency currency) internal view returns (address priceFeed) {
		if (!isBaseToken(currency)) {
			(, priceFeed, , , , , ) = getAssetInfoByAddress(POOL, currency);
		} else {
			priceFeed = baseTokenPriceFeed(POOL);
		}
	}

	function getPrice(address comet, address priceFeed) internal view returns (uint256 price) {
		Errors.InvalidFeed.selector.required(priceFeed != address(0));

		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x41976e0900000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, priceFeed))

			if iszero(staticcall(gas(), comet, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			price := mload(0x00)
		}

		Errors.InvalidPrice.selector.required(price != 0);
	}

	function totalsBasic(
		address comet
	)
		internal
		view
		returns (
			uint64 baseSupplyIndex,
			uint64 baseBorrowIndex,
			uint64 trackingSupplyIndex,
			uint64 trackingBorrowIndex,
			uint104 totalSupplyBase,
			uint104 totalBorrowBase,
			uint40 lastAccrualTime,
			uint8 pauseFlags
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xb9f0baf700000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, add(ptr, 0x20), 0x100)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			baseSupplyIndex := mload(add(ptr, 0x20))
			baseBorrowIndex := mload(add(ptr, 0x40))
			trackingSupplyIndex := mload(add(ptr, 0x60))
			trackingBorrowIndex := mload(add(ptr, 0x80))
			totalSupplyBase := mload(add(ptr, 0xa0))
			totalBorrowBase := mload(add(ptr, 0xc0))
			lastAccrualTime := mload(add(ptr, 0xe0))
			pauseFlags := mload(add(ptr, 0x100))
		}
	}

	function userBasic(
		address comet,
		address account
	)
		internal
		view
		returns (
			int104 principal,
			uint64 baseTrackingIndex,
			uint64 baseTrackingAccrued,
			uint16 assetsIn,
			uint8 reserved
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xdc4abafd00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, account))

			if iszero(staticcall(gas(), comet, ptr, 0x24, add(ptr, 0x40), 0xa0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			principal := mload(add(ptr, 0x40))
			baseTrackingIndex := mload(add(ptr, 0x60))
			baseTrackingAccrued := mload(add(ptr, 0x80))
			assetsIn := mload(add(ptr, 0xa0))
			reserved := mload(add(ptr, 0xc0))
		}
	}

	function borrowBalanceOf(address comet, address account) internal view returns (uint128 value) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x374c49b400000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, account))

			if iszero(staticcall(gas(), comet, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			value := mload(0x00)
		}
	}

	function collateralBalanceOf(
		address comet,
		Currency currency,
		address account
	) internal view returns (uint128 value) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x5c2549ee00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, account))
			mstore(add(ptr, 0x24), and(MASK_160_BITS, currency))

			if iszero(staticcall(gas(), comet, ptr, 0x44, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			value := mload(0x00)
		}
	}

	function getReserves(address comet) internal view returns (int256 reserves) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			reserves := mload(0x00)
		}
	}

	function getSupplyRate(address comet, uint256 utilization) internal view returns (uint64 supplyRate) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xd955759d00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), utilization)

			if iszero(staticcall(gas(), comet, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			supplyRate := mload(0x00)
		}
	}

	function getBorrowRate(address comet, uint256 utilization) internal view returns (uint64 borrowRate) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x9fa83b5a00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), utilization)

			if iszero(staticcall(gas(), comet, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			borrowRate := mload(0x00)
		}
	}

	function getAssetInfo(
		address comet,
		uint256 offset
	)
		internal
		view
		returns (
			Currency currency,
			address priceFeed,
			uint64 scale,
			uint64 borrowCollateralFactor,
			uint64 liquidateCollateralFactor,
			uint64 liquidationFactor,
			uint128 supplyCap
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xc8c7fe6b00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_8_BITS, offset))

			if iszero(staticcall(gas(), comet, ptr, 0x24, add(ptr, 0x40), 0x100)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			currency := mload(add(ptr, 0x60))
			priceFeed := mload(add(ptr, 0x80))
			scale := mload(add(ptr, 0xa0))
			borrowCollateralFactor := mload(add(ptr, 0xc0))
			liquidateCollateralFactor := mload(add(ptr, 0xf0))
			liquidationFactor := mload(add(ptr, 0x100))
			supplyCap := mload(add(ptr, 0x120))
		}
	}

	function getAssetInfoByAddress(
		address comet,
		Currency currency
	)
		internal
		view
		returns (
			uint8 offset,
			address priceFeed,
			uint64 scale,
			uint64 borrowCollateralFactor,
			uint64 liquidateCollateralFactor,
			uint64 liquidationFactor,
			uint128 supplyCap
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x3b3bec2e00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))

			if iszero(staticcall(gas(), comet, ptr, 0x24, add(ptr, 0x40), 0x100)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			offset := mload(add(ptr, 0x40))
			priceFeed := mload(add(ptr, 0x80))
			scale := mload(add(ptr, 0xa0))
			borrowCollateralFactor := div(mload(add(ptr, 0xc0)), DESCALE)
			liquidateCollateralFactor := div(mload(add(ptr, 0xf0)), DESCALE)
			liquidationFactor := div(mload(add(ptr, 0x100)), DESCALE)
			supplyCap := mload(add(ptr, 0x120))
		}
	}

	function numAssets(address comet) internal view returns (uint8 value) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xa46fe83b00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			value := mload(0x00)
		}
	}

	function isBaseToken(Currency currency) internal view returns (bool) {
		return currency == BASE_CURRENCY;
	}

	function baseToken(address comet) internal view returns (Currency currency) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xc55dae6300000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			currency := mload(0x00)
		}
	}

	function baseTokenPriceFeed(address comet) internal view returns (address priceFeed) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xe7dad6bd00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			priceFeed := mload(0x00)
		}
	}

	function baseScale(address comet) internal view returns (uint64 scale) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x44c1e5eb00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			scale := mload(0x00)
		}
	}

	function trackingIndexScale(address comet) internal view returns (uint64 scale) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xaba7f15e00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			scale := mload(0x00)
		}
	}

	function baseTrackingSupplySpeed(address comet) internal view returns (uint64 trackingSpeed) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x189bb2f100000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			trackingSpeed := mload(0x00)
		}
	}

	function baseTrackingBorrowSpeed(address comet) internal view returns (uint64 trackingSpeed) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x9ea99a5a00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			trackingSpeed := mload(0x00)
		}
	}

	function baseBorrowMin(address comet) internal view returns (uint104 value) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x300e6beb00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			value := mload(0x00)
		}
	}

	function baseMinForRewards(address comet) internal view returns (uint104 value) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x9364e18a00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), comet, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			value := mload(0x00)
		}
	}

	function presentValue(int104 principal, uint64 supplyIndex, uint64 borrowIndex) internal pure returns (int104) {
		if (principal < 0) {
			return -presentValue(uint104(-principal), borrowIndex).toInt104();
		} else {
			return presentValue(uint104(principal), supplyIndex).toInt104();
		}
	}

	function presentValue(uint104 principal, uint64 baseIndex) internal pure returns (uint104) {
		return mulScale(principal, baseIndex, BASE_INDEX_SCALE);
	}

	function principalValue(int104 present, uint64 supplyIndex, uint64 borrowIndex) internal pure returns (int104) {
		if (present < 0) {
			return -principalValueBorrow(uint104(-present), borrowIndex).toInt104();
		} else {
			return principalValueSupply(uint104(present), supplyIndex).toInt104();
		}
	}

	function principalValueSupply(uint104 present, uint64 supplyIndex) internal pure returns (uint104) {
		return divScale(present, supplyIndex, BASE_INDEX_SCALE);
	}

	function principalValueBorrow(uint104 present, uint64 borrowIndex) internal pure returns (uint104) {
		return (present * BASE_INDEX_SCALE + borrowIndex - 1) / borrowIndex;
	}

	function mulFactor(uint256 x, uint256 factor) internal pure returns (uint64) {
		return mulScale(x, factor, FACTOR_SCALE);
	}

	function divFactor(uint256 x, uint256 factor) internal pure returns (uint64) {
		return divScale(x, factor, FACTOR_SCALE);
	}

	function mulPrice(uint256 x, uint256 price, uint64 fromScale) internal pure returns (uint256) {
		return x.mulDiv(price, fromScale);
	}

	function divPrice(uint256 x, uint256 price, uint64 toScale) internal pure returns (uint256) {
		return x.mulDiv(toScale, price);
	}

	function mulScale(uint256 x, uint256 y, uint64 fromScale) internal pure returns (uint64) {
		return x.mulDiv(y, fromScale).toUint64();
	}

	function divScale(uint256 x, uint256 y, uint64 toScale) internal pure returns (uint64) {
		return x.mulDiv(toScale, y).toUint64();
	}

	function isAssetIn(uint16 assetsIn, uint8 offset) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			flag := and(assetsIn, shl(offset, 0x01))
		}
	}

	function isPaused(uint8 flags, uint8 offset) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			flag := and(flags, shl(offset, 0x01))
		}
	}
}
