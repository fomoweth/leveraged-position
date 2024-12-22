// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface IPositionDeployer {
	function deployPosition(bytes calldata params) external payable returns (address);

	function getPosition(
		address account,
		address lender,
		Currency collateralAsset,
		Currency liabilityAsset,
		uint256 nonce
	) external view returns (address);

	function getPosition(bytes32 salt) external view returns (address);
}
