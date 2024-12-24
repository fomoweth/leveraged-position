// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {ILender} from "./ILender.sol";
import {ILeveragedPosition} from "./ILeveragedPosition.sol";

interface IPositionDescriptor {
	function parseTicker(ILeveragedPosition position) external view returns (string memory);

	function parseTicker(
		ILender lender,
		Currency collateralAsset,
		Currency liabilityAsset
	) external view returns (string memory ticker);

	function parseDescription(ILeveragedPosition position) external view returns (string memory description);

	function parseDescription(
		ILender lender,
		Currency collateralAsset,
		Currency liabilityAsset
	) external view returns (string memory description);
}
