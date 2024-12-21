// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface IBulker {
	event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

	function ACTION_SUPPLY_STETH() external view returns (bytes32);

	function ACTION_WITHDRAW_STETH() external view returns (bytes32);

	function ACTION_SUPPLY_ASSET() external view returns (bytes32);

	function ACTION_SUPPLY_NATIVE_TOKEN() external view returns (bytes32);

	function ACTION_TRANSFER_ASSET() external view returns (bytes32);

	function ACTION_WITHDRAW_ASSET() external view returns (bytes32);

	function ACTION_WITHDRAW_NATIVE_TOKEN() external view returns (bytes32);

	function ACTION_CLAIM_REWARD() external view returns (bytes32);

	function invoke(bytes32[] calldata actions, bytes[] calldata data) external payable;

	function wrappedNativeToken() external view returns (Currency);

	function steth() external view returns (Currency);

	function wsteth() external view returns (Currency);

	function admin() external view returns (address);

	function sweepToken(address recipient, Currency asset) external;

	function sweepNativeToken(address recipient) external;

	function transferAdmin(address newAdmin) external;
}
