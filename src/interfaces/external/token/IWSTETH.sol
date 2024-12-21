// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20Metadata} from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/token/ERC20/extensions/IERC20Permit.sol";

interface IWSTETH is IERC20Metadata, IERC20Permit {
	function wrap(uint256 stETHAmount) external returns (uint256);

	function unwrap(uint256 wstETHAmount) external returns (uint256);

	function getWstETHByStETH(uint256 stETHAmount) external view returns (uint256);

	function getStETHByWstETH(uint256 wstETHAmount) external view returns (uint256);

	function stEthPerToken() external view returns (uint256);

	function tokensPerStEth() external view returns (uint256);

	function stETH() external view returns (address);

	function increaseAllowance(address spender, uint256 value) external;

	function decreaseAllowance(address spender, uint256 value) external;
}
