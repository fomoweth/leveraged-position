// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title AaveReserves
/// @dev Modified from https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/configuration/ReserveConfiguration.sol

library AaveReserves {
	uint256 internal constant BORROW_MASK = 					0x5555555555555555555555555555555555555555555555555555555555555555; // prettier-ignore
	uint256 internal constant COLLATERAL_MASK =					0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA; // prettier-ignore

	uint256 internal constant LTV_MASK =                       	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
	uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
	uint256 internal constant LIQUIDATION_BONUS_MASK =         	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
	uint256 internal constant DECIMALS_MASK =                  	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant ACTIVE_MASK =                    	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant FROZEN_MASK =                    	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant BORROWING_MASK =                 	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant STABLE_BORROWING_MASK =          	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant PAUSED_MASK =                    	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant SILOED_BORROWING_MASK =          	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant FLASHLOAN_ENABLED_MASK =         	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant RESERVE_FACTOR_MASK =            	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant BORROW_CAP_MASK =                	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant SUPPLY_CAP_MASK =                	0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  	0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant EMODE_CATEGORY_MASK =            	0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant UNBACKED_MINT_CAP_MASK =         	0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant DEBT_CEILING_MASK =              	0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant VIRTUAL_ACC_ACTIVE_MASK =        	0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

	uint256 internal constant LIQUIDATION_THRESHOLD_OFFSET = 16;
	uint256 internal constant LIQUIDATION_BONUS_OFFSET = 32;
	uint256 internal constant RESERVE_DECIMALS_OFFSET = 48;
	uint256 internal constant IS_ACTIVE_OFFSET = 56;
	uint256 internal constant IS_FROZEN_OFFSET = 57;
	uint256 internal constant BORROWING_ENABLED_OFFSET = 58;
	uint256 internal constant STABLE_BORROWING_ENABLED_OFFSET = 59;
	uint256 internal constant IS_PAUSED_OFFSET = 60;
	uint256 internal constant BORROWABLE_IN_ISOLATION_OFFSET = 61;
	uint256 internal constant SILOED_BORROWING_OFFSET = 62;
	uint256 internal constant FLASHLOAN_ENABLED_OFFSET = 63;
	uint256 internal constant RESERVE_FACTOR_OFFSET = 64;
	uint256 internal constant BORROW_CAP_OFFSET = 80;
	uint256 internal constant SUPPLY_CAP_OFFSET = 116;
	uint256 internal constant LIQUIDATION_PROTOCOL_FEE_OFFSET = 152;
	uint256 internal constant EMODE_CATEGORY_OFFSET = 168;
	uint256 internal constant UNBACKED_MINT_CAP_OFFSET = 176;
	uint256 internal constant DEBT_CEILING_OFFSET = 212;
	uint256 internal constant VIRTUAL_ACC_OFFSET = 252;

	uint256 internal constant SECONDS_PER_DAY = 86400;
	uint256 internal constant SECONDS_PER_YEAR = 31536000;

	uint256 internal constant DEBT_CEILING_DECIMALS = 2;
	uint16 internal constant MAX_RESERVES_COUNT = 128;

	bytes4 private constant INVALID_RESERVE_INDEX = 0x85e98beb; // InvalidReserveIndex()

	function getLtv(uint256 configuration) internal pure returns (uint256) {
		return decode(configuration, LTV_MASK, 0);
	}

	function getLiquidationThreshold(uint256 configuration) internal pure returns (uint256) {
		return decode(configuration, LIQUIDATION_THRESHOLD_MASK, LIQUIDATION_THRESHOLD_OFFSET);
	}

	function getDecimals(uint256 configuration) internal pure returns (uint256) {
		return decode(configuration, DECIMALS_MASK, RESERVE_DECIMALS_OFFSET);
	}

	function getActive(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, ACTIVE_MASK);
	}

	function getFrozen(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, FROZEN_MASK);
	}

	function getPaused(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, PAUSED_MASK);
	}

	function getBorrowableInIsolation(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, BORROWABLE_IN_ISOLATION_MASK);
	}

	function getSiloedBorrowing(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, SILOED_BORROWING_MASK);
	}

	function getBorrowingEnabled(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, BORROWING_MASK);
	}

	function getStableRateBorrowingEnabled(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, STABLE_BORROWING_MASK);
	}

	function getFlashLoanEnabled(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, FLASHLOAN_ENABLED_MASK);
	}

	function getReserveFactor(uint256 configuration) internal pure returns (uint256) {
		return decode(configuration, RESERVE_FACTOR_MASK, RESERVE_FACTOR_OFFSET);
	}

	function getBorrowCap(uint256 configuration) internal pure returns (uint256) {
		return decode(configuration, BORROW_CAP_MASK, BORROW_CAP_OFFSET);
	}

	function getSupplyCap(uint256 configuration) internal pure returns (uint256) {
		return decode(configuration, SUPPLY_CAP_MASK, SUPPLY_CAP_OFFSET);
	}

	function getEModeCategory(uint256 configuration) internal pure returns (uint256) {
		return decode(configuration, EMODE_CATEGORY_MASK, EMODE_CATEGORY_OFFSET);
	}

	function getUnbackedMintCap(uint256 configuration) internal pure returns (uint256) {
		return decode(configuration, UNBACKED_MINT_CAP_MASK, UNBACKED_MINT_CAP_OFFSET);
	}

	function getDebtCeiling(uint256 configuration) internal pure returns (uint256 debtCeiling) {
		return decode(configuration, DEBT_CEILING_MASK, DEBT_CEILING_OFFSET);
	}

	function getIsVirtualAccActive(uint256 configuration) internal pure returns (bool) {
		return getFlag(configuration, VIRTUAL_ACC_ACTIVE_MASK);
	}

	function getFlags(
		uint256 configuration
	) internal pure returns (bool isActive, bool isFrozen, bool isPaused, bool isBorrowingEnabled) {
		assembly ("memory-safe") {
			isActive := and(configuration, not(ACTIVE_MASK))
			isFrozen := and(configuration, not(FROZEN_MASK))
			isPaused := and(configuration, not(PAUSED_MASK))
			isBorrowingEnabled := and(configuration, not(BORROWING_MASK))
		}
	}

	function isAssetIn(uint256 userConfiguration, uint256 reserveIndex) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			if iszero(lt(reserveIndex, MAX_RESERVES_COUNT)) {
				mstore(0x00, INVALID_RESERVE_INDEX)
				revert(0x00, 0x04)
			}

			flag := and(shr(shl(0x01, reserveIndex), userConfiguration), 0x03)
		}
	}

	function isBorrowing(uint256 userConfiguration, uint256 reserveIndex) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			if iszero(lt(reserveIndex, MAX_RESERVES_COUNT)) {
				mstore(0x00, INVALID_RESERVE_INDEX)
				revert(0x00, 0x04)
			}

			flag := and(shr(shl(0x01, reserveIndex), userConfiguration), 0x01)
		}
	}

	function isBorrowingAny(uint256 userConfiguration) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			flag := and(userConfiguration, BORROW_MASK)
		}
	}

	function isSupplying(uint256 userConfiguration, uint256 reserveIndex) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			if iszero(lt(reserveIndex, MAX_RESERVES_COUNT)) {
				mstore(0x00, INVALID_RESERVE_INDEX)
				revert(0x00, 0x04)
			}

			flag := and(shr(add(shl(0x01, reserveIndex), 0x01), userConfiguration), 0x01)
		}
	}

	function isSupplyingAny(uint256 userConfiguration) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			flag := and(userConfiguration, COLLATERAL_MASK)
		}
	}

	function decode(uint256 configuration, uint256 mask, uint256 offset) internal pure returns (uint256 value) {
		assembly ("memory-safe") {
			value := shr(offset, and(configuration, not(mask)))
		}
	}

	function getFlag(uint256 configuration, uint256 mask) internal pure returns (bool flag) {
		assembly ("memory-safe") {
			flag := and(configuration, not(mask))
		}
	}
}
