// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IEmissionManager {
	struct RewardsConfigInput {
		uint88 emissionPerSecond;
		uint256 totalSupply;
		uint32 distributionEnd;
		address asset;
		address reward;
		address transferStrategy;
		address rewardOracle;
	}

	struct UserAssetBalance {
		address asset;
		uint256 userBalance;
		uint256 totalSupply;
	}

	struct UserData {
		uint104 index;
		uint128 accrued;
	}

	struct RewardData {
		uint104 index;
		uint88 emissionPerSecond;
		uint32 lastUpdateTimestamp;
		uint32 distributionEnd;
		mapping(address => UserData) usersData;
	}

	struct AssetData {
		mapping(address => RewardData) rewards;
		mapping(uint128 => address) availableRewards;
		uint128 availableRewardsCount;
		uint8 decimals;
	}

	event EmissionAdminUpdated(address indexed reward, address indexed oldAdmin, address indexed newAdmin);

	function configureAssets(RewardsConfigInput[] memory config) external;

	function setTransferStrategy(address reward, address transferStrategy) external;

	function setRewardOracle(address reward, address rewardOracle) external;

	function setDistributionEnd(address asset, address reward, uint32 newDistributionEnd) external;

	function setEmissionPerSecond(
		address asset,
		address[] calldata rewards,
		uint88[] calldata newEmissionsPerSecond
	) external;

	function setClaimer(address user, address claimer) external;

	function setEmissionAdmin(address reward, address admin) external;

	function setRewardsController(address controller) external;

	function getRewardsController() external view returns (address);

	function getEmissionAdmin(address reward) external view returns (address);
}
