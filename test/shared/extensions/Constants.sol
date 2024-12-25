// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAggregator} from "src/interfaces/external/chainlink/IAggregator.sol";
import {IFeedRegistry} from "src/interfaces/external/chainlink/IFeedRegistry.sol";
import {IQuoter} from "src/interfaces/external/uniswap/v3/IQuoter.sol";
import {IUniswapV3Factory} from "src/interfaces/external/uniswap/v3/IUniswapV3Factory.sol";
import {IPermit2} from "src/interfaces/external/uniswap/IPermit2.sol";
import {Currency} from "src/types/Currency.sol";

abstract contract Constants {
	address internal constant VM = address(uint160(uint256(keccak256("hevm cheat code"))));

	bytes10 internal constant UNLABELED_PREFIX = bytes10("unlabeled:");

	uint256 internal constant BLOCKS_PER_DAY = 7200;
	uint256 internal constant BLOCKS_PER_YEAR = 2628000;
	uint256 internal constant SECONDS_PER_BLOCK = 12;
	uint256 internal constant SECONDS_PER_DAY = 86400;
	uint256 internal constant SECONDS_PER_YEAR = 31536000;

	uint256 internal constant BPS = 1e4;

	uint256 internal constant MAX_UINT256 = (1 << 256) - 1;
	uint160 internal constant MAX_UINT160 = (1 << 160) - 1;
	uint128 internal constant MAX_UINT128 = (1 << 128) - 1;
	uint104 internal constant MAX_UINT104 = (1 << 104) - 1;
	uint64 internal constant MAX_UINT64 = (1 << 64) - 1;

	IUniswapV3Factory internal constant UNISWAP_V3_FACTORY =
		IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
	IQuoter internal constant UNISWAP_V3_QUOTER = IQuoter(0x5e55C9e631FAE526cd4B0526C4818D6e0a9eF0e3);
	IPermit2 internal constant PERMIT2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

	IFeedRegistry internal constant FEED_REGISTRY = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);

	Currency internal constant ETH = Currency.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
	Currency internal constant BTC = Currency.wrap(0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB);
	Currency internal constant USD = Currency.wrap(0x0000000000000000000000000000000000000348);

	bytes32 internal constant ERC1967_ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

	bytes32 internal constant ERC1967_IMPLEMENTATION_SLOT =
		0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	bytes32 internal constant ERC1967_BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

	bytes32 internal constant STETH_TOTAL_SHARES_SLOT =
		0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;

	uint256 internal constant CLONES_ARGS_MAX_LENGTH = 0xffd2; // 65490

	uint256 internal constant ERC1967_ARGS_MAX_LENGTH = 0xffc2; // 65474

	uint256 internal constant ERC1967I_ARGS_MAX_LENGTH = 0xffad; // 65453

	uint256 internal constant ERC1967_BEACON_PROXY_ARGS_MAX_LENGTH = 0xffad; // 65453

	uint256 internal constant ERC1967I_BEACON_PROXY_ARGS_MAX_LENGTH = 0xffa8; // 65448
}
