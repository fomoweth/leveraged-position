// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {IPool} from "./IPool.sol";

interface ITokenWrapper {
	struct PermitSignature {
		uint256 deadline;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	function supplyToken(uint256 amount, address onBehalfOf, uint16 referralCode) external returns (uint256);

	function supplyTokenWithPermit(
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode,
		PermitSignature calldata signature
	) external returns (uint256);

	function withdrawToken(uint256 amount, address to) external returns (uint256);

	function withdrawTokenWithPermit(
		uint256 amount,
		address to,
		PermitSignature calldata signature
	) external returns (uint256);

	function rescueTokens(Currency token, address to, uint256 amount) external;

	function rescueETH(address to, uint256 amount) external;

	function getTokenOutForTokenIn(uint256 amount) external view returns (uint256);

	function getTokenInForTokenOut(uint256 amount) external view returns (uint256);

	function TOKEN_IN() external view returns (Currency);

	function TOKEN_OUT() external view returns (Currency);

	function POOL() external view returns (IPool);
}
