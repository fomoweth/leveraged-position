// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {StdAssertions} from "forge-std/Test.sol";

import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {Currency} from "src/types/Currency.sol";

abstract contract Assertions is StdAssertions {
	using PercentageMath for uint256;

	function assertEq(Currency a, Currency b) internal pure virtual {
		assertEq(a.toAddress(), b.toAddress());
	}

	function assertEq(Currency a, Currency b, string memory err) internal pure virtual {
		assertEq(a.toAddress(), b.toAddress(), err);
	}

	function assertCloseTo(uint256 a, uint256 b) internal pure virtual {
		assertApproxEqRel(a, b, 0.05e18);
	}

	function assertCloseTo(uint256 a, uint256 b, string memory err) internal pure virtual {
		assertApproxEqRel(a, b, 0.05e18, err);
	}

	function assertCloseTo(uint256 a, uint256 b, uint256 percentDelta) internal pure virtual {
		assertCloseTo(a, b, percentDelta, "");
	}

	function assertCloseTo(uint256 a, uint256 b, uint256 percentDelta, string memory err) internal pure virtual {
		assertLe(percentDelta, 1e4, "percentDelta > 1e4");

		if (a < b) (a, b) = (b, a);
		uint256 delta = a - b;
		assertLe(delta, a.percentMul(percentDelta), err);
	}
}
