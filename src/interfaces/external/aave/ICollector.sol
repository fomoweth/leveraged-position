// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface ICollector {
	event NewFundsAdmin(address indexed fundsAdmin);

	event CreateStream(
		uint256 indexed streamId,
		address indexed sender,
		address indexed recipient,
		uint256 deposit,
		address tokenAddress,
		uint256 startTime,
		uint256 stopTime
	);

	event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

	event CancelStream(
		uint256 indexed streamId,
		address indexed sender,
		address indexed recipient,
		uint256 senderBalance,
		uint256 recipientBalance
	);

	struct Stream {
		uint256 deposit;
		uint256 ratePerSecond;
		uint256 remainingBalance;
		uint256 startTime;
		uint256 stopTime;
		address recipient;
		address sender;
		address tokenAddress;
		bool isEntity;
	}

	function ETH_MOCK_ADDRESS() external pure returns (address);

	function initialize(address fundsAdmin, uint256 nextStreamId) external;

	function getFundsAdmin() external view returns (address);

	function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

	function approve(Currency token, address recipient, uint256 amount) external;

	function transfer(Currency token, address recipient, uint256 amount) external;

	function setFundsAdmin(address admin) external;

	function createStream(
		address recipient,
		uint256 deposit,
		address tokenAddress,
		uint256 startTime,
		uint256 stopTime
	) external returns (uint256 streamId);

	function getStream(
		uint256 streamId
	)
		external
		view
		returns (
			address sender,
			address recipient,
			uint256 deposit,
			address tokenAddress,
			uint256 startTime,
			uint256 stopTime,
			uint256 remainingBalance,
			uint256 ratePerSecond
		);

	function withdrawFromStream(uint256 streamId, uint256 amount) external returns (bool);

	function cancelStream(uint256 streamId) external returns (bool);

	function getNextStreamId() external view returns (uint256);
}
