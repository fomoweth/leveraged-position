// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface ICometExt {
	struct TotalsBasic {
		uint64 baseSupplyIndex;
		uint64 baseBorrowIndex;
		uint64 trackingSupplyIndex;
		uint64 trackingBorrowIndex;
		uint104 totalSupplyBase;
		uint104 totalBorrowBase;
		uint40 lastAccrualTime;
		uint8 pauseFlags;
	}

	struct TotalsCollateral {
		uint128 totalSupplyAsset;
		uint128 reserved;
	}

	struct UserBasic {
		int104 principal;
		uint64 baseTrackingIndex;
		uint64 baseTrackingAccrued;
		uint16 assetsIn;
		uint8 reserved;
	}

	struct UserCollateral {
		uint128 balance;
		uint128 reserved;
	}

	struct LiquidatorPoints {
		uint32 numAbsorbs;
		uint64 numAbsorbed;
		uint128 approxSpend;
		uint32 reserved;
	}

	event Approval(address indexed owner, address indexed spender, uint256 amount);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function allow(address manager, bool isAllowed) external;

	function allowBySig(
		address owner,
		address manager,
		bool isAllowed,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function hasPermission(address owner, address manager) external view returns (bool);

	function isAllowed(address owner, address manager) external view returns (bool);

	function collateralBalanceOf(address account, Currency asset) external view returns (uint128);

	function baseTrackingAccrued(address account) external view returns (uint64);

	function baseAccrualScale() external pure returns (uint64);

	function baseIndexScale() external pure returns (uint64);

	function factorScale() external pure returns (uint64);

	function priceScale() external pure returns (uint64);

	function maxAssets() external pure returns (uint8);

	function totalsBasic() external view returns (TotalsBasic memory);

	function totalsCollateral(Currency asset) external view returns (TotalsCollateral memory);

	function userBasic(address account) external view returns (UserBasic memory);

	function userCollateral(address account, Currency asset) external view returns (UserCollateral memory);

	function userNonce(address account) external view returns (uint);

	function liquidatorPoints(address account) external view returns (LiquidatorPoints memory);

	function version() external view returns (string memory);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);
}
