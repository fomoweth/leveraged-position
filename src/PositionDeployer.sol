// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MASK_160_BITS} from "src/libraries/BitMasks.sol";
import {BytesLib} from "src/libraries/BytesLib.sol";
import {Errors} from "src/libraries/Errors.sol";
import {StorageSlot} from "src/libraries/StorageSlot.sol";
import {TypeConversion} from "src/libraries/TypeConversion.sol";
import {Currency} from "src/types/Currency.sol";
import {ContractLocker} from "src/base/ContractLocker.sol";
import {Initializable} from "src/base/Initializable.sol";

/// @title PositionDeployer

contract PositionDeployer is ContractLocker, Initializable {
	using BytesLib for bytes;
	using StorageSlot for bytes32;
	using TypeConversion for address;
	using TypeConversion for bytes32;

	uint256 internal constant PROXY_BYTECODE = 0x67363d3d37363d34f03d5260086018f3;

	bytes32 internal constant PROXY_BYTECODE_HASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

	/// keccak256(bytes("PositionDeployed(address,address,bytes32)"))
	bytes32 internal constant DEPLOYED_TOPIC = 0x736d08594162989ad1b9b6a5c7d38bcd4253d3ad2c516de3aae5afa2c08c3a43;

	/// bytes32(uint256(keccak256("Positions")) - 1)
	bytes32 internal constant POSITIONS_SLOT = 0x66b3960cb22d3f03aa7e631a9037f2bf707761d360715760189e13b796b49a52;

	uint8 internal constant MAX_POSITIONS_LENGTH = (1 << 8) - 1;

	constructor() {
		_disableInitializers();
	}

	function initialize(bytes calldata params) external initializer {}

	function createPosition(bytes calldata params) public payable virtual lock returns (address position) {
		bytes calldata creationCode = params.toBytes(0);
		bytes calldata constructorParams = params.toBytes(1);

		Errors.required(creationCode.length != 0, Errors.EmptyCreationCode.selector);
		Errors.required(constructorParams.length != 0, Errors.EmptyConstructor.selector);

		bytes memory bytecode = abi.encodePacked(msg.sender.asBytes32(), constructorParams);

		bytes32 salt = keccak256(bytecode);
		uint8 nonce;

		// compute the deterministic address of the position with the given parameters,
		// increment the salt by one if the position at computed address exists already
		while (isContract(position = addressOf(salt))) {
			unchecked {
				Errors.required(++nonce <= MAX_POSITIONS_LENGTH, Errors.ExceededMaxLimit.selector);
				salt = bytes32(uint256(salt) + nonce);
			}
		}

		bytecode = abi.encodePacked(creationCode, bytecode);

		// use CREATE3 to deploy the position then store the address of the position mapped with its salt
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
	) public view virtual returns (address) {
		return getPosition(encodeSalt(account, lender, collateralAsset, liabilityAsset, nonce));
	}

	function getPosition(bytes32 salt) public view virtual returns (address position) {
		return POSITIONS_SLOT.deriveMapping(salt).sload().asAddress();
	}

	function isContract(address target) internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := iszero(iszero(extcodesize(target)))
		}
	}

	function addressOf(bytes32 salt) internal view virtual returns (address position) {
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
	) internal pure virtual returns (bytes32 salt) {
		assembly ("memory-safe") {
			mstore(0x00, and(MASK_160_BITS, account))
			mstore(0x20, and(MASK_160_BITS, lender))
			mstore(0x40, and(MASK_160_BITS, collateralAsset))
			mstore(0x60, and(MASK_160_BITS, liabilityAsset))

			salt := add(keccak256(0x00, 0x80), nonce)
		}
	}
}
