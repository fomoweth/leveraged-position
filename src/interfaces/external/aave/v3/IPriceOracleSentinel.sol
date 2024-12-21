// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

interface IPriceOracleSentinel {
	event SequencerOracleUpdated(address newSequencerOracle);

	event GracePeriodUpdated(uint256 newGracePeriod);

	function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

	function isBorrowAllowed() external view returns (bool);

	function isLiquidationAllowed() external view returns (bool);

	function setSequencerOracle(address newSequencerOracle) external;

	function setGracePeriod(uint256 newGracePeriod) external;

	function getSequencerOracle() external view returns (address);

	function getGracePeriod() external view returns (uint256);
}
