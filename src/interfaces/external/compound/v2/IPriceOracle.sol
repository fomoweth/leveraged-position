// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AggregatorInterface} from "src/interfaces/external/chainlink/AggregatorInterface.sol";
import {ICToken} from "./ICToken.sol";

interface IPriceOracle {
	struct TokenConfig {
		uint8 underlyingAssetDecimals;
		AggregatorInterface priceFeed;
		uint256 fixedPrice;
	}

	struct LoadConfig {
		uint8 underlyingAssetDecimals;
		ICToken cToken;
		AggregatorInterface priceFeed;
		uint256 fixedPrice;
	}

	function getConfig(ICToken cToken) external view returns (TokenConfig memory);

	function getUnderlyingPrice(ICToken cToken) external view returns (uint256);

	function owner() external view returns (address);

	function pendingOwner() external view returns (address);

	function addConfig(LoadConfig memory config) external;

	function updateConfigPriceFeed(ICToken cToken, AggregatorInterface priceFeed) external;

	function updateConfigFixedPrice(ICToken cToken, uint256 fixedPrice) external;

	function removeConfig(ICToken cToken) external;
}
