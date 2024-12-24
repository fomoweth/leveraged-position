// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {StdAssertions} from "forge-std/Test.sol";

import {Currency} from "src/types/Currency.sol";

abstract contract Assertions is StdAssertions {
	function assertEq(Currency a, Currency b) internal pure virtual {
		assertEq(a.toAddress(), b.toAddress());
	}

	function assertEq(Currency a, Currency b, string memory err) internal pure virtual {
		assertEq(a.toAddress(), b.toAddress(), err);
	}

	function assertCloseTo(uint256 a, uint256 b, uint16 percentDelta) internal pure virtual {
		assertLe(percentDelta, 1e4, "percentDelta > 1e4");
		assertApproxEqRel(a, b, percentDelta * 1e14);
	}

	function assertCloseTo(uint256 a, uint256 b, uint16 percentDelta, string memory err) internal pure virtual {
		assertLe(percentDelta, 1e4, "percentDelta > 1e4");
		assertApproxEqRel(a, b, percentDelta * 1e14, err);
	}
}
