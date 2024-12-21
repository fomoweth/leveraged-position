// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AggregatorInterface} from "../chainlink/AggregatorInterface.sol";
import {IACLManager} from "./v3/IACLManager.sol";

interface ICLSynchronicityPriceAdapter {
	function latestAnswer() external view returns (int256);

	function description() external view returns (string memory);

	function decimals() external view returns (uint8);
}

interface IPriceCapAdapter is ICLSynchronicityPriceAdapter {
	struct PriceCapUpdateParams {
		uint104 snapshotRatio;
		uint48 snapshotTimestamp;
		uint16 maxYearlyRatioGrowthPercent;
	}

	event CapParametersUpdated(
		uint256 snapshotRatio,
		uint256 snapshotTimestamp,
		uint256 maxRatioGrowthPerSecond,
		uint16 maxYearlyRatioGrowthPercent
	);

	function setCapParameters(PriceCapUpdateParams memory priceCapParams) external;

	function PERCENTAGE_FACTOR() external view returns (uint256);

	function MINIMAL_RATIO_INCREASE_LIFETIME() external view returns (uint256);

	function SECONDS_PER_YEAR() external view returns (uint256);

	function BASE_TO_USD_AGGREGATOR() external view returns (AggregatorInterface);

	function RATIO_PROVIDER() external view returns (address);

	function ACL_MANAGER() external view returns (IACLManager);

	function DECIMALS() external view returns (uint8);

	function RATIO_DECIMALS() external view returns (uint8);

	function MINIMUM_SNAPSHOT_DELAY() external view returns (uint48);

	function getRatio() external view returns (int256);

	function getSnapshotRatio() external view returns (uint256);

	function getSnapshotTimestamp() external view returns (uint256);

	function getMaxRatioGrowthPerSecond() external view returns (uint256);

	function getMaxYearlyGrowthRatePercent() external view returns (uint256);

	function isCapped() external view returns (bool);
}

interface IPriceCapAdapterStable is ICLSynchronicityPriceAdapter {
	event PriceCapUpdated(int256 priceCap);

	function ASSET_TO_USD_AGGREGATOR() external view returns (AggregatorInterface);

	function ACL_MANAGER() external view returns (IACLManager);

	function setPriceCap(int256 priceCap) external;

	function isCapped() external view returns (bool);
}
