// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface IRewardsController {
	struct RewardsConfigInput {
		uint88 emissionPerSecond;
		uint256 totalSupply;
		uint32 distributionEnd;
		Currency asset;
		Currency reward;
		address transferStrategy;
		address rewardOracle;
	}

	event ClaimerSet(address indexed user, address indexed claimer);

	event RewardsClaimed(
		address indexed user,
		Currency indexed reward,
		address indexed to,
		address claimer,
		uint256 amount
	);

	event TransferStrategyInstalled(Currency indexed reward, address indexed transferStrategy);

	event RewardOracleUpdated(Currency indexed reward, address indexed rewardOracle);

	event AssetConfigUpdated(
		Currency indexed asset,
		address indexed reward,
		uint256 oldEmission,
		uint256 newEmission,
		uint256 oldDistributionEnd,
		uint256 newDistributionEnd,
		uint256 assetIndex
	);

	event Accrued(
		Currency indexed asset,
		address indexed reward,
		address indexed user,
		uint256 assetIndex,
		uint256 userIndex,
		uint256 rewardsAccrued
	);

	// IRewardsController

	function setClaimer(address user, address claimer) external;

	function setTransferStrategy(Currency reward, address transferStrategy) external;

	function setRewardOracle(Currency reward, address rewardOracle) external;

	function getRewardOracle(Currency reward) external view returns (address);

	function getClaimer(address user) external view returns (address);

	function getTransferStrategy(Currency reward) external view returns (address);

	function configureAssets(RewardsConfigInput[] memory config) external;

	function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;

	function claimRewards(
		Currency[] calldata assets,
		uint256 amount,
		address to,
		Currency reward
	) external returns (uint256 totalRewards);

	function claimRewardsOnBehalf(
		Currency[] calldata assets,
		uint256 amount,
		address user,
		address to,
		Currency reward
	) external returns (uint256 totalRewards);

	function claimRewardsToSelf(
		Currency[] calldata assets,
		uint256 amount,
		Currency reward
	) external returns (uint256 totalRewards);

	function claimAllRewards(
		Currency[] calldata assets,
		address to
	) external returns (Currency[] memory rewardsList, uint256[] memory claimedAmounts);

	function claimAllRewardsOnBehalf(
		Currency[] calldata assets,
		address user,
		address to
	) external returns (Currency[] memory rewardsList, uint256[] memory claimedAmounts);

	function claimAllRewardsToSelf(
		Currency[] calldata assets
	) external returns (Currency[] memory rewardsList, uint256[] memory claimedAmounts);

	// IRewardsDistributor

	function setDistributionEnd(Currency asset, Currency reward, uint32 newDistributionEnd) external;

	function setEmissionPerSecond(
		Currency asset,
		address[] calldata rewards,
		uint88[] calldata newEmissionsPerSecond
	) external;

	function getDistributionEnd(Currency asset, Currency reward) external view returns (uint256);

	function getUserAssetIndex(address user, Currency asset, Currency reward) external view returns (uint256);

	function getRewardsData(
		Currency asset,
		Currency reward
	)
		external
		view
		returns (uint256 index, uint256 emissionPerSecond, uint256 lastUpdateTimestamp, uint256 distributionEnd);

	function getAssetIndex(Currency asset, Currency reward) external view returns (uint256 oldIndex, uint256 newIndex);

	function getRewardsByAsset(Currency asset) external view returns (Currency[] memory);

	function getRewardsList() external view returns (Currency[] memory);

	function getUserAccruedRewards(address user, Currency reward) external view returns (uint256 totalAccrued);

	function getUserRewards(
		Currency[] calldata assets,
		address user,
		Currency reward
	) external view returns (uint256 unclaimed);

	function getAllUserRewards(
		Currency[] calldata assets,
		address user
	) external view returns (Currency[] memory rewardsList, uint256[] memory unclaimedAmounts);

	function getAssetDecimals(Currency asset) external view returns (uint8 decimals);

	function EMISSION_MANAGER() external view returns (address);

	function getEmissionManager() external view returns (address);
}
