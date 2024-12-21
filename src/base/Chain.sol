// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MASK_40_BITS} from "src/libraries/BitMasks.sol";

/// @title Chain
/// @notice Provides functions for identifying the current chain and retrieving the block number and timestamp

abstract contract Chain {
	uint256 private constant ETHEREUM_CHAIN_ID = 1;
	uint256 private constant OPTIMISM_CHAIN_ID = 10;
	uint256 private constant POLYGON_CHAIN_ID = 137;
	uint256 private constant ARBITRUM_CHAIN_ID = 42161;

	address private constant ARB_SYS = 0x0000000000000000000000000000000000000064;

	function() internal view returns (uint40) internal immutable blockNumber;

	constructor() {
		blockNumber = !runningOnArbitrum() ? _blockNumber : _arbBlockNumber;
	}

	function blockTimestamp() internal view returns (uint40 bts) {
		assembly ("memory-safe") {
			bts := and(MASK_40_BITS, timestamp())
		}
	}

	function runningOnEthereum() internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := eq(chainid(), ETHEREUM_CHAIN_ID)
		}
	}

	function runningOnOptimism() internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := eq(chainid(), OPTIMISM_CHAIN_ID)
		}
	}

	function runningOnPolygon() internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := eq(chainid(), POLYGON_CHAIN_ID)
		}
	}

	function runningOnArbitrum() internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := eq(chainid(), ARBITRUM_CHAIN_ID)
		}
	}

	function _blockNumber() private view returns (uint40 bn) {
		assembly ("memory-safe") {
			bn := and(MASK_40_BITS, number())
		}
	}

	function _arbBlockNumber() private view returns (uint40 bn) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xa3b1b31d00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), ARB_SYS, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			bn := and(MASK_40_BITS, mload(0x00))
		}
	}
}
