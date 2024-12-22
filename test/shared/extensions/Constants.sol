// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IFeedRegistry} from "src/interfaces/external/chainlink/IFeedRegistry.sol";
import {IQuoter} from "src/interfaces/external/uniswap/v3/IQuoter.sol";
import {IUniswapV3Factory} from "src/interfaces/external/uniswap/v3/IUniswapV3Factory.sol";
import {IPermit2} from "src/interfaces/external/uniswap/IPermit2.sol";
import {Currency} from "src/types/Currency.sol";

abstract contract Constants {
	bytes10 internal constant UNLABELED_PREFIX = bytes10("unlabeled:");

	uint256 internal constant MAX_UINT256 = (1 << 256) - 1;
	uint160 internal constant MAX_UINT160 = (1 << 160) - 1;
	uint128 internal constant MAX_UINT128 = (1 << 128) - 1;
	uint104 internal constant MAX_UINT104 = (1 << 104) - 1;
	uint64 internal constant MAX_UINT64 = (1 << 64) - 1;

	IUniswapV3Factory internal constant V3_FACTORY = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
	IQuoter internal constant V3_QUOTER = IQuoter(0x5e55C9e631FAE526cd4B0526C4818D6e0a9eF0e3);
	IPermit2 internal constant PERMIT2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

	IFeedRegistry internal constant FEED_REGISTRY = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);

	Currency internal constant ETH = Currency.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
	Currency internal constant BTC = Currency.wrap(0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB);
	Currency internal constant USD = Currency.wrap(0x0000000000000000000000000000000000000348);
}
