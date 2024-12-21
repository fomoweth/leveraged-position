// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface AggregatorInterface {
	event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

	event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

	struct Phase {
		uint16 id;
		AggregatorInterface aggregator;
	}

	// V3

	function aggregator() external view returns (AggregatorInterface);

	function phaseId() external view returns (uint16);

	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	function getRoundData(
		uint80 roundId
	) external view returns (uint80 round, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function latestRoundData()
		external
		view
		returns (uint80 round, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function proposedGetRoundData(
		uint80 roundId
	) external view returns (uint80 round, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function proposedLatestRoundData()
		external
		view
		returns (uint80 round, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	// V2

	function latestAnswer() external view returns (int256);

	function latestTimestamp() external view returns (uint256);

	function latestRound() external view returns (uint256);

	function getAnswer(uint256 roundId) external view returns (int256);

	function getTimestamp(uint256 roundId) external view returns (uint256);

	function phaseAggregators(uint16 phaseId) external view returns (AggregatorInterface);

	function proposedAggregator() external view returns (AggregatorInterface);

	// Admin

	function proposeAggregator(AggregatorInterface aggregator) external;

	function confirmAggregator(AggregatorInterface aggregator) external;

	function accessController() external view returns (address);

	function setController(address accessController) external;

	function owner() external view returns (address);

	function transferOwnership(address account) external;

	function acceptOwnership() external;
}
