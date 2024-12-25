// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {IAggregator} from "./IAggregator.sol";

interface IFeedRegistry {
	struct Phase {
		uint16 phaseId;
		uint80 startingAggregatorRoundId;
		uint80 endingAggregatorRoundId;
	}

	event FeedProposed(
		Currency indexed asset,
		Currency indexed denomination,
		address indexed proposedAggregator,
		address currentAggregator,
		address sender
	);

	event FeedConfirmed(
		Currency indexed asset,
		Currency indexed denomination,
		address indexed latestAggregator,
		address previousAggregator,
		uint16 nextPhaseId,
		address sender
	);

	// V3 AggregatorV3Interface

	function decimals(Currency base, Currency quote) external view returns (uint8);

	function description(Currency base, Currency quote) external view returns (string memory);

	function version(Currency base, Currency quote) external view returns (uint256);

	function latestRoundData(
		Currency base,
		Currency quote
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function getRoundData(
		Currency base,
		Currency quote,
		uint80 round
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	// V2 AggregatorInterface

	function latestAnswer(Currency base, Currency quote) external view returns (int256 answer);

	function latestTimestamp(Currency base, Currency quote) external view returns (uint256 timestamp);

	function latestRound(Currency base, Currency quote) external view returns (uint256 roundId);

	function getAnswer(Currency base, Currency quote, uint256 roundId) external view returns (int256 answer);

	function getTimestamp(Currency base, Currency quote, uint256 roundId) external view returns (uint256 timestamp);

	// Registry getters

	function getFeed(Currency base, Currency quote) external view returns (IAggregator aggregator);

	function getPhaseFeed(Currency base, Currency quote, uint16 phaseId) external view returns (IAggregator aggregator);

	function isFeedEnabled(address aggregator) external view returns (bool);

	function getPhase(Currency base, Currency quote, uint16 phaseId) external view returns (Phase memory phase);

	// Round helpers

	function getRoundFeed(Currency base, Currency quote, uint80 roundId) external view returns (IAggregator aggregator);

	function getPhaseRange(
		Currency base,
		Currency quote,
		uint16 phaseId
	) external view returns (uint80 startingRoundId, uint80 endingRoundId);

	function getPreviousRoundId(
		Currency base,
		Currency quote,
		uint80 roundId
	) external view returns (uint80 previousRoundId);

	function getNextRoundId(Currency base, Currency quote, uint80 roundId) external view returns (uint80 nextRoundId);

	// Feed management

	function proposeFeed(Currency base, Currency quote, address aggregator) external;

	function confirmFeed(Currency base, Currency quote, address aggregator) external;

	// Proposed aggregator

	function getProposedFeed(Currency base, Currency quote) external view returns (IAggregator proposedAggregator);

	function proposedGetRoundData(
		Currency base,
		Currency quote,
		uint80 roundId
	) external view returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function proposedLatestRoundData(
		Currency base,
		Currency quote
	) external view returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	// Phases
	function getCurrentPhaseId(Currency base, Currency quote) external view returns (uint16 currentPhaseId);

	function typeAndVersion() external pure returns (string memory);

	function owner() external returns (address);

	function transferOwnership(address recipient) external;

	function acceptOwnership() external;
}
