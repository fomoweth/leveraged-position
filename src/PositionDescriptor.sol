// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPositionDescriptor} from "src/interfaces/IPositionDescriptor.sol";
import {IConfigurator} from "src/interfaces/IConfigurator.sol";
import {ILender} from "src/interfaces/ILender.sol";
import {ILeveragedPosition} from "src/interfaces/ILeveragedPosition.sol";
import {BytesLib} from "src/libraries/BytesLib.sol";
import {CurrencyNamer} from "src/libraries/CurrencyNamer.sol";
import {Currency} from "src/types/Currency.sol";
import {Initializable} from "src/base/Initializable.sol";

/// @title PositionDescriptor
/// @notice Provides parsers for generating the ticker and description of a position

contract PositionDescriptor is IPositionDescriptor, Initializable {
	using BytesLib for bytes;

	IConfigurator internal configurator;

	constructor() {
		disableInitializer();
	}

	function initialize(bytes calldata params) external initializer {
		configurator = IConfigurator(params.toAddress(0));
	}

	function parseTicker(ILeveragedPosition position) external view returns (string memory) {
		return parseTicker(ILender(position.lender()), position.collateralAsset(), position.liabilityAsset());
	}

	function parseTicker(
		ILender lender,
		Currency collateralAsset,
		Currency liabilityAsset
	) public view returns (string memory) {
		return
			string.concat(
				CurrencyNamer.bytes32ToString(lender.PROTOCOL()),
				": ",
				CurrencyNamer.symbol(collateralAsset),
				"/",
				CurrencyNamer.symbol(liabilityAsset)
			);
	}

	function parseDescription(ILeveragedPosition position) external view returns (string memory) {
		return parseDescription(ILender(position.lender()), position.collateralAsset(), position.liabilityAsset());
	}

	function parseDescription(
		ILender lender,
		Currency collateralAsset,
		Currency liabilityAsset
	) public view returns (string memory) {
		return
			string.concat(
				CurrencyNamer.bytes32ToString(lender.PROTOCOL()),
				": ",
				"Long ",
				CurrencyNamer.symbol(collateralAsset),
				" / ",
				"Short ",
				CurrencyNamer.symbol(liabilityAsset)
			);
	}
}
