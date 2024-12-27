// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Errors} from "src/libraries/Errors.sol";
import {Math} from "src/libraries/Math.sol";
import {Path} from "src/libraries/Path.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {PositionMath} from "src/libraries/PositionMath.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {StorageSlot} from "src/libraries/StorageSlot.sol";
import {TypeConversion} from "src/libraries/TypeConversion.sol";
import {Currency} from "src/types/Currency.sol";
import {LeveragedPosition} from "src/LeveragedPosition.sol";

contract MockLeveragedPosition is LeveragedPosition {
	using Math for uint256;
	using Path for bytes;
	using PercentageMath for uint256;
	using PositionMath for uint256;
	using SafeCast for uint256;
	using StorageSlot for bytes32;
	using TypeConversion for bytes32;
	using TypeConversion for uint256;
	using TypeConversion for int256;

	constructor(
		address _owner,
		address _lender,
		Currency _collateralAsset,
		Currency _liabilityAsset
	) LeveragedPosition(_owner, _lender, _collateralAsset, _liabilityAsset) {}

	function getCachedStorage(bytes32 key) public view returns (bytes32) {
		return cache(key).tload();
	}

	function setCachedStorage(bytes32 key, bytes32 value) public {
		cache(key).tstore(value);
	}
}
