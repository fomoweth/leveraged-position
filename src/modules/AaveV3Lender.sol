// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AaveReserves} from "src/libraries/AaveReserves.sol";
import {MASK_160_BITS, MASK_128_BITS, MASK_104_BITS, MASK_80_BITS, MASK_40_BITS, MASK_8_BITS} from "src/libraries/BitMasks.sol";
import {Errors} from "src/libraries/Errors.sol";
import {Math} from "src/libraries/Math.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {WadRayMath} from "src/libraries/WadRayMath.sol";
import {Currency} from "src/types/Currency.sol";
import {Lender} from "./Lender.sol";

/// @title AaveV3Lender
/// @notice Lending adapter to invoke actions of Aave V3 Protocol

contract AaveV3Lender is Lender {
	using AaveReserves for uint256;
	using Math for uint256;
	using PercentageMath for uint256;
	using SafeCast for uint256;
	using WadRayMath for uint256;

	uint8 internal constant REFERRAL_CODE = 0;

	uint8 internal constant VARIABLE_INTEREST_MODE = 2;

	uint16 internal constant MIN_COLLATERAL_FACTOR = 1000;

	constructor(
		bytes32 _protocol,
		address _lendingPool,
		address _priceOracle,
		address _rewardsController
	) Lender(_protocol, _lendingPool, _priceOracle, _rewardsController) {}

	function supply(Currency currency, uint256 amount) external payable returns (int256) {
		approveIfNeeded(currency, POOL, amount);

		supply(POOL, currency, amount);

		(uint256 reserveIndex, uint40 accrualTime) = getReserveIndices(POOL, currency, true);

		return encodeCallResult(amount.toInt104(), reserveIndex.toUint104(), accrualTime);
	}

	function borrow(Currency currency, uint256 amount) external payable returns (int256) {
		borrow(POOL, currency, amount);

		(uint256 reserveIndex, uint40 accrualTime) = getReserveIndices(POOL, currency, false);

		return encodeCallResult(-amount.toInt104(), reserveIndex.toUint104(), accrualTime);
	}

	function repay(Currency currency, uint256 amount) external payable returns (int256) {
		approveIfNeeded(currency, POOL, amount);

		repay(POOL, currency, amount);

		(uint256 reserveIndex, uint40 accrualTime) = getReserveIndices(POOL, currency, false);

		return encodeCallResult(amount.toInt104(), reserveIndex.toUint104(), accrualTime);
	}

	function redeem(Currency currency, uint256 amount) external payable returns (int256) {
		redeem(POOL, currency, amount);

		(uint256 reserveIndex, uint40 accrualTime) = getReserveIndices(POOL, currency, true);

		return encodeCallResult(-amount.toInt104(), reserveIndex.toUint104(), accrualTime);
	}

	function claim(address recipient) external payable {
		claimAllRewards(REWARDS_CONTROLLER, getReservesIn(address(this)), recipient);
	}

	function setAsCollateral(Currency currency, bool useAsCollateral) external payable {
		address pool = POOL;

		assembly ("memory-safe") {
			let ptr := mload(0x40)
			mstore(0x40, add(ptr, 0x44))

			mstore(ptr, 0x5a3b74b900000000000000000000000000000000000000000000000000000000) // setUserUseReserveAsCollateral(address,bool)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))
			mstore(add(ptr, 0x24), and(MASK_8_BITS, useAsCollateral))

			if iszero(call(gas(), pool, 0x00, ptr, 0x44, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}

	function supply(address pool, Currency currency, uint256 amount) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x617ba03700000000000000000000000000000000000000000000000000000000) // supply(address,uint256,address,uint16)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))
			mstore(add(ptr, 0x24), amount)
			mstore(add(ptr, 0x44), and(MASK_160_BITS, address()))
			mstore(add(ptr, 0x64), and(MASK_8_BITS, REFERRAL_CODE))

			if iszero(call(gas(), pool, 0x00, ptr, 0x84, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(ptr, 0xa0))
		}
	}

	function borrow(address pool, Currency currency, uint256 amount) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xa415bcad00000000000000000000000000000000000000000000000000000000) // borrow(address,uint256,uint256,uint16,address)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))
			mstore(add(ptr, 0x24), amount)
			mstore(add(ptr, 0x44), and(MASK_8_BITS, VARIABLE_INTEREST_MODE))
			mstore(add(ptr, 0x64), and(MASK_8_BITS, REFERRAL_CODE))
			mstore(add(ptr, 0x84), and(MASK_160_BITS, address()))

			if iszero(call(gas(), pool, 0x00, ptr, 0xa4, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(ptr, 0xc0))
		}
	}

	function repay(address pool, Currency currency, uint256 amount) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x573ade8100000000000000000000000000000000000000000000000000000000) // repay(address,uint256,uint256,address)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))
			mstore(add(ptr, 0x24), amount)
			mstore(add(ptr, 0x44), and(MASK_8_BITS, VARIABLE_INTEREST_MODE))
			mstore(add(ptr, 0x64), and(MASK_160_BITS, address()))

			if iszero(call(gas(), pool, 0x00, ptr, 0x84, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(ptr, 0xa0))
		}
	}

	function redeem(address pool, Currency currency, uint256 amount) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x69328dec00000000000000000000000000000000000000000000000000000000) // withdraw(address,uint256,address)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))
			mstore(add(ptr, 0x24), amount)
			mstore(add(ptr, 0x44), and(MASK_160_BITS, address()))

			if iszero(call(gas(), pool, 0x00, ptr, 0x64, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(ptr, 0x80))
		}
	}

	function claimAllRewards(address rewardsController, Currency[] memory reserves, address recipient) internal {
		if (reserves.length == 0) return;

		assembly ("memory-safe") {
			if iszero(recipient) {
				recipient := address()
			}

			let length := mload(reserves)
			let size := shl(0x05, length)
			let ptr := mload(0x40)

			mstore(ptr, 0xbb492bf500000000000000000000000000000000000000000000000000000000) // claimAllRewards(address[],address)
			mstore(add(ptr, 0x04), 0x40)
			mstore(add(ptr, 0x24), and(MASK_160_BITS, recipient))
			mstore(add(ptr, 0x44), length)

			let pos := add(ptr, 0x64)
			let guard := add(pos, size)

			// prettier-ignore
			for { let offset := add(reserves, 0x20) } lt(pos, guard) { } {
				mstore(pos, mload(offset))
				pos := add(pos, 0x20)
				offset := add(offset, 0x20)
			}

			mstore(0x40, and(add(guard, 0x1f), not(0x1f)))

			if iszero(call(gas(), rewardsController, 0x00, ptr, add(size, 0x64), 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}

	function getReservesIn(address account) public view returns (Currency[] memory reserves) {
		uint256 userConfiguration = getUserConfiguration(POOL, account);
		if (userConfiguration != 0) {
			Currency[] memory assets = getReservesList(POOL);
			uint256 length = assets.length;
			uint256 count;
			uint256 offset;

			unchecked {
				reserves = new Currency[](length * 2);

				while (offset < length) {
					// check if the currency at current index is either being supplied or borrowed
					if (userConfiguration.isAssetIn(offset)) {
						// fetch reserve token addresses of the currency from lending pool
						(Currency aToken, , Currency variableDebtToken) = getReserveCurrencies(POOL, assets[offset]);

						// append the aToken to the reserves array then increment the count if the currency is being supplied
						if (userConfiguration.isSupplying(offset)) {
							reserves[count] = aToken;
							count = count + 1;
						}

						// append the variableDebtToken to the reserves array then increment the count if the currency is being borrowed
						if (userConfiguration.isBorrowing(offset)) {
							reserves[count] = variableDebtToken;
							count = count + 1;
						}
					}

					offset = offset + 1;
				}
			}

			assembly ("memory-safe") {
				// set the length of the reserves array to the count if necessary
				if xor(length, count) {
					mstore(reserves, count)
				}
			}
		}
	}

	function getReservesList() external view returns (Currency[] memory) {
		return getReservesList(POOL);
	}

	function getRewardsList() external view returns (Currency[] memory) {
		return getRewardsList(REWARDS_CONTROLLER);
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
		uint256 ltv;
		(totalCollateralInBase, totalDebtInBase, availableBorrowsInBase, , ltv, healthFactor) = getUserAccountData(
			POOL,
			account
		);

		collateralUsage = totalDebtInBase.percentDiv(totalCollateralInBase.percentMul(ltv));
	}

	function getAccountCollateral(Currency currency, address account) external view returns (uint256) {
		(Currency aToken, , ) = getReserveCurrencies(POOL, currency);
		return aToken.balanceOf(account);
	}

	function getAccountLiability(Currency currency, address account) external view returns (uint256) {
		(, , Currency variableDebtToken) = getReserveCurrencies(POOL, currency);
		return variableDebtToken.balanceOf(account);
	}

	function getAvailableLiquidity(Currency currency) external view returns (uint256) {
		unchecked {
			(
				uint256 configuration,
				,
				,
				uint128 borrowIndex,
				,
				,
				,
				,
				Currency aToken,
				Currency stableDebtToken,
				Currency variableDebtToken,
				,
				,
				,

			) = getReserveData(POOL, currency);

			(bool isActive, bool isFrozen, bool isPaused, bool isBorrowingEnabled) = configuration.getFlags();

			if (isActive && !isFrozen && !isPaused && isBorrowingEnabled) {
				uint256 totalLiquidity = currency.balanceOf(Currency.unwrap(aToken));

				uint256 borrowCap = configuration.getBorrowCap() * (10 ** configuration.getDecimals());
				if (borrowCap == 0) return totalLiquidity;

				uint256 totalDebt = stableDebtToken.totalSupply() +
					scaledTotalSupply(variableDebtToken).rayMul(borrowIndex);

				if (borrowCap > totalDebt) return totalLiquidity.min(borrowCap - totalDebt);
			}

			return 0;
		}
	}

	function getAccruedRewards(address account) external view returns (Currency[] memory, uint256[] memory) {
		return getAccruedRewards(REWARDS_CONTROLLER, account);
	}

	function getAccruedRewards(Currency rewardAsset, address account) external view returns (uint256) {
		return getUserAccruedRewards(REWARDS_CONTROLLER, account, rewardAsset);
	}

	function getCollateralFactor(Currency currency) external view returns (uint256 ltv) {
		if ((ltv = getConfiguration(POOL, currency).getLtv()) < MIN_COLLATERAL_FACTOR) return 0;
	}

	function getLiquidationFactor(Currency currency) external view returns (uint256) {
		return getConfiguration(POOL, currency).getLiquidationThreshold();
	}

	function getRatio(Currency currency) external view returns (uint256 ratio) {
		uint256 answer = getAssetPrice(PRICE_ORACLE, currency);

		address aggregator = getChainLinkAggregator(getSourceOfAsset(PRICE_ORACLE, currency));
		required(aggregator != address(0), Errors.InvalidFeed.selector);

		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xfeaf968c00000000000000000000000000000000000000000000000000000000) // latestRoundData()

			if iszero(staticcall(gas(), aggregator, ptr, 0x04, add(ptr, 0x20), 0xa0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			ratio := or(
				add(
					shl(208, and(MASK_40_BITS, mload(add(ptr, 0x80)))),
					shl(128, and(MASK_80_BITS, mload(add(ptr, 0x20))))
				),
				and(MASK_128_BITS, answer)
			)
		}
	}

	function getPrice(Currency currency) external view returns (uint256) {
		return getAssetPrice(PRICE_ORACLE, currency);
	}

	function getReservesList(address pool) internal view returns (Currency[] memory reserves) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xd1946dbc00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pool, ptr, 0x04, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			returndatacopy(ptr, 0x00, returndatasize())

			let length := div(sub(returndatasize(), 0x40), 0x20)

			reserves := mload(0x40)
			mstore(reserves, length)

			let pos := add(reserves, 0x20)
			let offset := sub(add(ptr, 0x40), pos)
			let guard := add(pos, shl(0x05, length))
			mstore(0x40, guard)

			// prettier-ignore
			for { } 0x01 { } {
				mstore(pos, mload(add(pos, offset)))
				pos := add(pos, 0x20)

				if eq(pos, guard) { break }
			}
		}
	}

	function getRewardsList(address rewardsController) internal view returns (Currency[] memory rewardAssets) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xb45ac1a900000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), rewardsController, ptr, 0x04, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			returndatacopy(ptr, 0x00, returndatasize())

			let length := div(sub(returndatasize(), 0x40), 0x20)

			rewardAssets := mload(0x40)
			mstore(rewardAssets, length)

			let pos := add(rewardAssets, 0x20)
			let offset := sub(add(ptr, 0x40), pos)
			let guard := add(pos, shl(0x05, length))
			mstore(0x40, guard)

			// prettier-ignore
			for { } 0x01 { } {
				mstore(pos, mload(add(pos, offset)))
				pos := add(pos, 0x20)

				if eq(pos, guard) { break }
			}
		}
	}

	function getAccruedRewards(
		address rewardsController,
		address account
	) internal view returns (Currency[] memory rewardAssets, uint256[] memory accruedRewards) {
		Currency[] memory reserves = getReservesIn(account);
		if (reserves.length != 0) return getAllUserRewards(rewardsController, reserves, account);
	}

	function getAllUserRewards(
		address rewardsController,
		Currency[] memory reserves,
		address account
	) internal view returns (Currency[] memory rewardAssets, uint256[] memory accruedRewards) {
		bytes memory returndata;

		assembly ("memory-safe") {
			let length := mload(reserves)
			let size := shl(0x05, length)
			let offset := add(reserves, 0x20)

			let ptr := mload(0x40)

			mstore(ptr, 0x4c0369c300000000000000000000000000000000000000000000000000000000) // getAllUserRewards(address[],address)
			mstore(add(ptr, 0x04), 0x40)
			mstore(add(ptr, 0x24), and(MASK_160_BITS, account))
			mstore(add(ptr, 0x44), length)

			let pos := add(ptr, 0x64)
			let guard := add(pos, size)

			// prettier-ignore
			for { } lt(pos, guard) { } {
				mstore(pos, mload(offset))
				pos := add(pos, 0x20)
				offset := add(offset, 0x20)
			}

			mstore(0x40, and(add(guard, 0x1f), not(0x1f)))

			if iszero(staticcall(gas(), rewardsController, ptr, add(size, 0x64), 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(returndata, add(returndatasize(), 0x20)))
			mstore(returndata, returndatasize())
			returndatacopy(add(returndata, 0x20), 0x00, returndatasize())
		}

		return abi.decode(returndata, (Currency[], uint256[]));
	}

	function getUserAccruedRewards(
		address rewardsController,
		address account,
		Currency reward
	) internal view returns (uint256 accrued) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xb022418c00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, account))
			mstore(add(ptr, 0x24), and(MASK_160_BITS, reward))

			if iszero(staticcall(gas(), rewardsController, ptr, 0x44, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			accrued := mload(0x00)
		}
	}

	function getReserveCurrencies(
		address pool,
		Currency currency
	) internal view returns (Currency aToken, Currency stableDebtToken, Currency variableDebtToken) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x35ea6a7500000000000000000000000000000000000000000000000000000000) // getReserveData(address)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))

			if iszero(staticcall(gas(), pool, ptr, 0x24, add(ptr, 0x40), 0x1e0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			aToken := mload(add(ptr, 0x140))
			stableDebtToken := mload(add(ptr, 0x160))
			variableDebtToken := mload(add(ptr, 0x180))
		}
	}

	function getReserveIndices(
		address pool,
		Currency currency,
		bool direction
	) internal view returns (uint128 reserveIndex, uint40 lastAccrualTime) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x35ea6a7500000000000000000000000000000000000000000000000000000000) // getReserveData(address)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))

			if iszero(staticcall(gas(), pool, ptr, 0x24, add(ptr, 0x40), 0x1e0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			switch direction
			case 0x00 {
				reserveIndex := mload(add(ptr, 0xa0))
			}
			default {
				reserveIndex := mload(add(ptr, 0x60))
			}

			lastAccrualTime := mload(add(ptr, 0x100))
		}
	}

	function getReserveData(
		address pool,
		Currency currency
	)
		internal
		view
		returns (
			uint256 configuration,
			uint128 liquidityIndex,
			uint128 currentLiquidityRate,
			uint128 variableBorrowIndex,
			uint128 currentVariableBorrowRate,
			uint128 currentStableBorrowRate,
			uint40 lastUpdateTimestamp,
			uint16 id,
			Currency aToken,
			Currency stableDebtToken,
			Currency variableDebtToken,
			address interestRateStrategy,
			uint128 accruedToTreasury,
			uint128 unbacked,
			uint128 isolationModeTotalDebt
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x35ea6a7500000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))

			if iszero(staticcall(gas(), pool, ptr, 0x24, add(ptr, 0x40), 0x1e0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			configuration := mload(add(ptr, 0x40))
			liquidityIndex := mload(add(ptr, 0x60))
			currentLiquidityRate := mload(add(ptr, 0x80))
			variableBorrowIndex := mload(add(ptr, 0xa0))
			currentVariableBorrowRate := mload(add(ptr, 0xc0))
			currentStableBorrowRate := mload(add(ptr, 0xe0))
			lastUpdateTimestamp := mload(add(ptr, 0x100))
			id := mload(add(ptr, 0x120))
			aToken := mload(add(ptr, 0x140))
			stableDebtToken := mload(add(ptr, 0x160))
			variableDebtToken := mload(add(ptr, 0x180))
			interestRateStrategy := mload(add(ptr, 0x1a0))
			accruedToTreasury := mload(add(ptr, 0x1c0))
			unbacked := mload(add(ptr, 0x1e0))
			isolationModeTotalDebt := mload(add(ptr, 0x200))
		}
	}

	function getUserAccountData(
		address pool,
		address account
	)
		internal
		view
		returns (
			uint256 totalCollateralInBase,
			uint256 totalDebtInBase,
			uint256 availableBorrowsInBase,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xbf92857c00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, account))

			if iszero(staticcall(gas(), pool, ptr, 0x24, add(ptr, 0x40), 0xc0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			totalCollateralInBase := mload(add(ptr, 0x40))
			totalDebtInBase := mload(add(ptr, 0x60))
			availableBorrowsInBase := mload(add(ptr, 0x80))
			currentLiquidationThreshold := mload(add(ptr, 0xa0))
			ltv := mload(add(ptr, 0xc0))
			healthFactor := mload(add(ptr, 0xe0))
		}
	}

	function getConfiguration(address pool, Currency currency) internal view returns (uint256 configuration) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xc44b11f700000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))

			if iszero(staticcall(gas(), pool, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			configuration := mload(0x00)
		}
	}

	function getUserConfiguration(address pool, address account) internal view returns (uint256 configuration) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x4417a58300000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, account))

			if iszero(staticcall(gas(), pool, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			configuration := mload(0x00)
		}
	}

	function getEModeCategoryData(
		address pool,
		uint256 categoryId
	) internal view returns (uint16 ltv, uint16 liquidationThreshold, uint16 liquidationBonus, address priceSource) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x6c6f6ae100000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_8_BITS, categoryId))

			if iszero(staticcall(gas(), pool, ptr, 0x24, add(ptr, 0x40), 0xa0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			ltv := mload(add(ptr, 0x60))
			liquidationThreshold := mload(add(ptr, 0x80))
			liquidationBonus := mload(add(ptr, 0xa0))
			priceSource := mload(add(ptr, 0xc0))
		}
	}

	function getUserEMode(address pool, address account) internal view returns (uint8 categoryId) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xeddf1b7900000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, account))

			if iszero(staticcall(gas(), pool, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			categoryId := mload(0x00)
		}
	}

	function setUserEMode(address pool, uint256 categoryId) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x28530a4700000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_8_BITS, categoryId))

			if iszero(call(gas(), pool, 0x00, ptr, 0x24, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(ptr, 0x40))
		}
	}

	function scaledBalanceOf(Currency reserve, address account) internal view returns (uint256 value) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xb3596f0700000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, account))

			if iszero(staticcall(gas(), reserve, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			value := mload(0x00)
		}
	}

	function scaledTotalSupply(Currency reserve) internal view returns (uint256 value) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xb1bf962d00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), reserve, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			value := mload(0x00)
		}
	}

	function getAssetPrice(address oracle, Currency currency) internal view virtual returns (uint256 price) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xb3596f0700000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))

			if iszero(staticcall(gas(), oracle, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			price := mload(0x00)
		}

		required(price != 0, Errors.InvalidPrice.selector);
	}

	function getSourceOfAsset(address oracle, Currency currency) internal view returns (address source) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x92bf2be000000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), and(MASK_160_BITS, currency))

			if iszero(staticcall(gas(), oracle, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			source := mload(0x00)
		}
	}

	function getChainLinkAggregator(address source) internal view returns (address aggregator) {
		assembly ("memory-safe") {
			function fetch(target, ptr) -> ret {
				if staticcall(gas(), target, ptr, 0x04, 0x00, 0x20) {
					ret := mload(0x00)
				}
			}

			let ptr := mload(0x40)

			mstore(ptr, 0x668a0f024ebdc284d221087cde4aedab00000000000000000000000000000000) // latestRound(), ASSET_TO_USD_AGGREGATOR(), BASE_TO_USD_AGGREGATOR(), PEG_TO_BASE()

			if fetch(source, ptr) {
				aggregator := source
			}

			if iszero(aggregator) {
				aggregator := fetch(source, add(ptr, 0x04))
			}

			if iszero(aggregator) {
				aggregator := fetch(source, add(ptr, 0x08))
			}

			if iszero(aggregator) {
				aggregator := fetch(source, add(ptr, 0x0c))
			}
		}
	}
}
