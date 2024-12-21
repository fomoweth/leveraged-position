// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface IIncentivesController {
	event AssetConfigUpdated(Currency indexed asset, uint256 emission);

	event AssetIndexUpdated(Currency indexed asset, uint256 index);

	event UserIndexUpdated(address indexed user, Currency indexed asset, uint256 index);

	event RewardsAccrued(address indexed user, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

	// IAaveDistributionManager

	function PRECISION() external view returns (uint8);

	function EMISSION_MANAGER() external view returns (address);

	function DISTRIBUTION_END() external view returns (uint256);

	function setDistributionEnd(uint256 distributionEnd) external;

	function getDistributionEnd() external view returns (uint256);

	function getUserAssetData(address user, Currency asset) external view returns (uint256 index);

	function getAssetData(
		Currency asset
	) external view returns (uint256 index, uint256 emissionsPerSecond, uint256 lastUpdateTimestamp);

	function assets(
		Currency asset
	) external view returns (uint104 emissionPerSecond, uint104 index, uint40 lastUpdateTimestamp);

	// IAaveIncentivesController

	function setClaimer(address user, address claimer) external;

	function getClaimer(address user) external view returns (address);

	struct AssetConfigInput {
		uint128 emissionPerSecond;
		uint256 totalStaked;
		address underlyingAsset;
	}

	struct UserStakeInput {
		Currency underlyingAsset;
		uint256 stakedByUser;
		uint256 totalStaked;
	}

	function configureAssets(AssetConfigInput[] calldata assetsConfigInput) external;

	function configureAssets(Currency[] calldata assets, uint256[] calldata emissionsPerSecond) external;

	function handleAction(Currency asset, uint256 userBalance, uint256 totalSupply) external;

	function getRewardsBalance(Currency[] calldata assets, address user) external view returns (uint256 unclaimed);

	function claimRewards(Currency[] calldata assets, uint256 amount, address to) external returns (uint256 claimed);

	function claimRewardsOnBehalf(
		Currency[] calldata assets,
		uint256 amount,
		address user,
		address to
	) external returns (uint256 claimed);

	function claimRewardsToSelf(Currency[] calldata assets, uint256 amount) external returns (uint256 claimed);

	function getUserUnclaimedRewards(address user) external view returns (uint256 unclaimed);

	function REVISION() external view returns (uint8);

	function rewardToken() external view returns (Currency);

	function STAKE_TOKEN() external view returns (Currency);

	function REWARDS_VAULT() external view returns (address);
}
