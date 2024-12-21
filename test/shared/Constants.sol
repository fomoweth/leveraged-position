// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

abstract contract Constants {
	bytes10 internal constant UNLABELED_PREFIX = bytes10("unlabeled:");

	uint256 internal constant ETHEREUM_CHAIN_ID = 1;
	uint256 internal constant OPTIMISM_CHAIN_ID = 10;
	uint256 internal constant POLYGON_CHAIN_ID = 137;
	uint256 internal constant ARBITRUM_CHAIN_ID = 42161;

	uint256 internal constant MAX_UINT256 = (1 << 256) - 1;
	uint160 internal constant MAX_UINT160 = (1 << 160) - 1;
	uint128 internal constant MAX_UINT128 = (1 << 128) - 1;

	address internal constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
	address internal constant UNISWAP_V3_QUOTER = 0x5e55C9e631FAE526cd4B0526C4818D6e0a9eF0e3;
	address internal constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

	Currency internal constant STETH = Currency.wrap(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
}
