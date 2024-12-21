// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface ICometRewards {
	struct RewardConfig {
		Currency token;
		uint64 rescaleFactor;
		bool shouldUpscale;
		uint256 multiplier;
	}

	struct RewardOwed {
		Currency token;
		uint256 owed;
	}

	// events

	event GovernorTransferred(address indexed oldGovernor, address indexed newGovernor);

	event RewardsClaimedSet(address indexed user, address indexed comet, uint256 amount);

	event RewardClaimed(address indexed src, address indexed recipient, Currency indexed token, uint256 amount);

	function claim(address comet, address src, bool shouldAccrue) external;

	function claimTo(address comet, address src, address to, bool shouldAccrue) external;

	function getRewardOwed(address comet, address account) external returns (RewardOwed memory);

	function rewardConfig(address comet) external view returns (RewardConfig memory);

	function rewardsClaimed(address comet, address account) external view returns (uint256);

	function setRewardConfig(address comet, Currency token) external;

	function setRewardConfigWithMultiplier(address comet, Currency token, uint256 multiplier) external;

	function setRewardsClaimed(address comet, address[] calldata users, uint256[] calldata claimedAmounts) external;

	function withdrawToken(Currency token, address to, uint256 amount) external;

	function transferGovernor(address newGovernor) external;

	function governor() external view returns (address);
}
