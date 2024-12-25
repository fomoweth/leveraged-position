// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPositionDeployer} from "src/interfaces/IPositionDeployer.sol";
import {IConfigurator} from "src/interfaces/IConfigurator.sol";
import {MASK_160_BITS} from "src/libraries/BitMasks.sol";
import {BytesLib} from "src/libraries/BytesLib.sol";
import {Errors} from "src/libraries/Errors.sol";
import {StorageSlot} from "src/libraries/StorageSlot.sol";
import {TypeConversion} from "src/libraries/TypeConversion.sol";
import {Currency} from "src/types/Currency.sol";
import {ContractLocker} from "src/base/ContractLocker.sol";
import {Initializable} from "src/base/Initializable.sol";
import {Validations} from "src/base/Validations.sol";

/// @title PositionDeployer
/// @notice Deploys the position contracts with the given parameters permissionlessly

contract PositionDeployer is IPositionDeployer, ContractLocker, Initializable, Validations {
	using BytesLib for bytes;
	using StorageSlot for bytes32;
	using TypeConversion for address;
	using TypeConversion for bytes32;

	uint256 private constant PROXY_BYTECODE = 0x67363d3d37363d34f03d5260086018f3;

	bytes32 private constant PROXY_BYTECODE_HASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

	/// keccak256(bytes("PositionDeployed(address,address,bytes32)"))
	bytes32 private constant DEPLOYED_TOPIC = 0x736d08594162989ad1b9b6a5c7d38bcd4253d3ad2c516de3aae5afa2c08c3a43;

	/// bytes32(uint256(keccak256("Positions")) - 1)
	bytes32 private constant POSITIONS_SLOT = 0x66b3960cb22d3f03aa7e631a9037f2bf707761d360715760189e13b796b49a52;

	uint256 public constant REVISION = 0x01;

	IConfigurator internal configurator;

	constructor() {
		disableInitializer();
	}

	function initialize(bytes calldata params) external initializer {
		configurator = IConfigurator(params.toAddress(0));
	}

	function deployPosition(bytes calldata params) external payable lock returns (address position) {
		bytes calldata creationCode = params.toBytes(0);
		bytes calldata constructorParams = params.toBytes(1);

		required(creationCode.length != 0, Errors.EmptyCreationCode.selector);
		required(constructorParams.length != 0, Errors.EmptyConstructor.selector);

		// append the owner's address to the beginning of the constructor parameters, then compute the salt
		bytes memory bytecode = abi.encodePacked(msg.sender.asBytes32(), constructorParams);

		bytes32 salt = keccak256(bytecode);

		// compute the deterministic address of the position using the given parameters
		// if a position already exists at the computed address, increment the salt by one
		while (isContract(position = addressOf(salt))) {
			unchecked {
				salt = bytes32(uint256(salt) + 1);
			}
		}

		// append the provided creation code to the beginning of the encoded constructor parameters for deployment
		bytecode = abi.encodePacked(creationCode, bytecode);

		// use CREATE3 to deploy the position, then store the position's address mapped with its salt
		assembly ("memory-safe") {
			mstore(0x00, PROXY_BYTECODE)

			let proxy := create2(0x00, 0x10, 0x10, salt)

			if iszero(proxy) {
				mstore(0x00, 0xd49e7d74) // ProxyCreationFailed()
				revert(0x1c, 0x04)
			}

			mstore(0x14, proxy)
			mstore(0x00, 0xd694)
			mstore8(0x34, 0x01)

			position := keccak256(0x1e, 0x17)

			if iszero(
				and(
					iszero(iszero(extcodesize(position))),
					call(gas(), proxy, 0x00, add(bytecode, 0x20), mload(bytecode), 0x00, 0x00)
				)
			) {
				mstore(0x00, 0xa28c2473) // ContractCreationFailed()
				revert(0x1c, 0x04)
			}

			log4(0x00, 0x00, DEPLOYED_TOPIC, position, caller(), salt)
		}

		POSITIONS_SLOT.deriveMapping(salt).sstore(position.asBytes32());
	}

	function getPosition(
		address account,
		address lender,
		Currency collateralAsset,
		Currency liabilityAsset,
		uint256 nonce
	) external view returns (address) {
		return getPosition(encodeSalt(account, lender, collateralAsset, liabilityAsset, nonce));
	}

	function getPosition(bytes32 salt) public view returns (address position) {
		return POSITIONS_SLOT.deriveMapping(salt).sload().asAddress();
	}

	function isContract(address target) internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := iszero(iszero(extcodesize(target)))
		}
	}

	function addressOf(bytes32 salt) internal view returns (address position) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(0x00, address())
			mstore8(0x0b, 0xff)
			mstore(0x20, salt)
			mstore(0x40, PROXY_BYTECODE_HASH)
			mstore(0x14, keccak256(0x0b, 0x55))
			mstore(0x40, ptr)
			mstore(0x00, 0xd694)
			mstore8(0x34, 0x01)

			position := keccak256(0x1e, 0x17)
		}
	}

	function encodeSalt(
		address account,
		address lender,
		Currency collateralAsset,
		Currency liabilityAsset,
		uint256 nonce
	) internal pure returns (bytes32 salt) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, and(MASK_160_BITS, account))
			mstore(add(ptr, 0x20), and(MASK_160_BITS, lender))
			mstore(add(ptr, 0x40), and(MASK_160_BITS, collateralAsset))
			mstore(add(ptr, 0x60), and(MASK_160_BITS, liabilityAsset))

			salt := add(keccak256(ptr, 0x80), nonce)
		}
	}

	function getRevision() internal pure virtual override returns (uint256) {
		return REVISION;
	}
}
