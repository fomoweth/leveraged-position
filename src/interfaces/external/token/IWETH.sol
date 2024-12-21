// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20Metadata} from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH is IERC20Metadata {
	function deposit() external payable;

	function withdraw(uint256 amount) external;
}
