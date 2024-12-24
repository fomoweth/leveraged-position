// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IConfigurator} from "src/interfaces/IConfigurator.sol";
import {Errors} from "src/libraries/Errors.sol";
import {StorageSlot} from "src/libraries/StorageSlot.sol";
import {TypeConversion} from "src/libraries/TypeConversion.sol";
import {Ownable} from "src/base/Ownable.sol";

/// @title AddressResolver
/// @notice Main registry of protocol contracts
/// @dev Modified from https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/configuration/PoolAddressesProvider.sol
/// and https://github.com/Vectorized/solady/blob/main/src/utils/ERC1967Factory.sol

contract Configurator is IConfigurator, Ownable {
	using Errors for bytes4;
	using StorageSlot for bytes32;
	using TypeConversion for address;
	using TypeConversion for bytes32;

	/// keccak256(bytes("Deployed(address,address)"))
	bytes32 private constant DEPLOYED_TOPIC = 0x09e48df7857bd0c1e0d31bb8a85d42cf1874817895f171c917f6ee2cea73ec20;

	/// keccak256(bytes("Upgraded(address,address)"))
	bytes32 private constant UPGRADED_TOPIC = 0x5d611f318680d00598bb735d61bacf0c514c6b50e1e5ad30040a4df2b12791c7;

	/// uint256(keccak256("Addresses")) - 1
	bytes32 private constant ADDRESSES_SLOT = 0x67c14ec595f48137cacef9bcaa1219f029491ada758d8ab6d68d9a5281ed279c;

	/// uint256(keccak256("eip1967.proxy.implementation")) - 1
	bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	bytes32 private constant POSITION_DEPLOYER = "POSITION_DEPLOYER";
	bytes32 private constant POSITION_DESCRIPTOR = "POSITION_DESCRIPTOR";

	constructor(address _initialOwner) {
		_checkNewOwner(_initialOwner);
		_initializeOwner(_initialOwner);
	}

	function getAddress(bytes32 id) public view returns (address value) {
		Errors.AddressNotSet.selector.required(
			(value = ADDRESSES_SLOT.deriveMapping(id).sload().asAddress()) != address(0)
		);
	}

	function setAddress(bytes32 id, address newAddress) public onlyOwner {
		ADDRESSES_SLOT.deriveMapping(id).sstore(newAddress.asBytes32());

		emit AddressSet(id, newAddress);
	}

	function setAddressAsProxy(bytes32 id, address newImplementation) public onlyOwner {
		address proxy = ADDRESSES_SLOT.deriveMapping(id).sload().asAddress();

		if (proxy == address(0)) {
			ADDRESSES_SLOT.deriveMapping(id).sstore((proxy = _deployAndCall(newImplementation)).asBytes32());
		} else {
			_upgradeAndCall(proxy, newImplementation);
		}

		IMPLEMENTATION_SLOT.deriveMapping(id).sstore(newImplementation.asBytes32());

		emit AddressSetAsProxy(id, proxy, newImplementation);
	}

	function getPositionDeployer() external view returns (address) {
		return getAddress(POSITION_DEPLOYER);
	}

	function setPositionDeployerImpl(address newImplementation) external {
		setAddressAsProxy(POSITION_DEPLOYER, newImplementation);
	}

	function getPositionDescriptor() external view returns (address) {
		return getAddress(POSITION_DESCRIPTOR);
	}

	function setPositionDescriptorImpl(address newImplementation) external {
		setAddressAsProxy(POSITION_DESCRIPTOR, newImplementation);
	}

	function _upgradeAndCall(address proxy, address implementation) private {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, implementation)
			mstore(add(ptr, 0x20), IMPLEMENTATION_SLOT)
			mstore(add(ptr, 0x40), 0x439fab9100000000000000000000000000000000000000000000000000000000) // initialize(bytes)
			mstore(add(ptr, 0x44), 0x20)
			mstore(add(ptr, 0x64), 0x20)
			mstore(add(ptr, 0x84), address())

			if iszero(call(gas(), proxy, 0x00, ptr, 0xa4, 0x00, 0x00)) {
				if iszero(returndatasize()) {
					mstore(0x00, 0x55299b49) // UpgradeFailed()
					revert(0x1c, 0x04)
				}

				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			log3(0x00, 0x00, UPGRADED_TOPIC, proxy, implementation)
		}
	}

	function _deployAndCall(address implementation) private returns (address proxy) {
		bytes32 ptr = _initCode();

		assembly ("memory-safe") {
			proxy := create(0x00, add(ptr, 0x13), 0x88)

			if iszero(proxy) {
				mstore(0x00, 0xd49e7d74) // ProxyCreationFailed()
				revert(0x1c, 0x04)
			}

			mstore(ptr, implementation)
			mstore(add(ptr, 0x20), IMPLEMENTATION_SLOT)
			mstore(add(ptr, 0x40), 0x439fab9100000000000000000000000000000000000000000000000000000000) // initialize(bytes)
			mstore(add(ptr, 0x44), 0x20)
			mstore(add(ptr, 0x64), 0x20)
			mstore(add(ptr, 0x84), address())

			if iszero(call(gas(), proxy, 0x00, ptr, 0xa4, 0x00, 0x00)) {
				if iszero(returndatasize()) {
					mstore(0x00, 0x19b991a8) // InitializationFailed()
					revert(0x1c, 0x04)
				}

				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			log3(0x00, 0x00, DEPLOYED_TOPIC, proxy, implementation)
		}
	}

	function _initCode() private view returns (bytes32 ptr) {
		assembly ("memory-safe") {
			ptr := mload(0x40)

			switch shr(112, address())
			case 0x00 {
				mstore(add(ptr, 0x75), 0x604c573d6000fd)
				mstore(add(ptr, 0x6e), 0x3d3560203555604080361115604c5736038060403d373d3d355af43d6000803e)
				mstore(add(ptr, 0x4e), 0x3735a920a3ca505d382bbc545af43d6000803e604c573d6000fd5b3d6000f35b)
				mstore(add(ptr, 0x2e), 0x14605157363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc)
				mstore(add(ptr, 0x0e), address())
				mstore(ptr, 0x60793d8160093d39f33d3d336d)
			}
			default {
				mstore(add(ptr, 0x7b), 0x6052573d6000fd)
				mstore(add(ptr, 0x74), 0x3d356020355560408036111560525736038060403d373d3d355af43d6000803e)
				mstore(add(ptr, 0x54), 0x3735a920a3ca505d382bbc545af43d6000803e6052573d6000fd5b3d6000f35b)
				mstore(add(ptr, 0x34), 0x14605757363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc)
				mstore(add(ptr, 0x14), address())
				mstore(ptr, 0x607f3d8160093d39f33d3d3373)
			}
		}
	}

	function _initializeOwnerGuard() internal pure virtual override returns (bool) {
		return true;
	}
}
