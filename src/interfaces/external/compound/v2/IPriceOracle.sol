// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAggregator} from "src/interfaces/external/chainlink/IAggregator.sol";
import {ICToken} from "./ICToken.sol";

interface IPriceOracle {
	struct TokenConfig {
		uint8 underlyingAssetDecimals;
		IAggregator priceFeed;
		uint256 fixedPrice;
	}

	struct LoadConfig {
		uint8 underlyingAssetDecimals;
		ICToken cToken;
		IAggregator priceFeed;
		uint256 fixedPrice;
	}

	function getConfig(ICToken cToken) external view returns (TokenConfig memory);

	function getUnderlyingPrice(ICToken cToken) external view returns (uint256);

	function owner() external view returns (address);

	function pendingOwner() external view returns (address);

	function addConfig(LoadConfig memory config) external;

	function updateConfigPriceFeed(ICToken cToken, IAggregator priceFeed) external;

	function updateConfigFixedPrice(ICToken cToken, uint256 fixedPrice) external;

	function removeConfig(ICToken cToken) external;
}
