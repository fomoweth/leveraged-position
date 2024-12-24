// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Vm} from "forge-std/Vm.sol";
import {ERC1967Proxy} from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import {ProxyAdmin} from "@openzeppelin/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Bytes32Cast} from "test/shared/utils/Bytes32Cast.sol";
import {Constants} from "./Constants.sol";

abstract contract ProxyHelper is Constants {
	using Bytes32Cast for bytes32;

	Vm private constant vm = Vm(VM);

	function deployERC1967Proxy(
		string memory name,
		address implementation,
		bytes memory data
	) internal returns (address proxy) {
		vm.label((proxy = deployERC1967Proxy(implementation, data)), string.concat(name, " Proxy"));
	}

	function deployERC1967Proxy(string memory name, address implementation) internal returns (address) {
		return deployERC1967Proxy(name, implementation, emptyData());
	}

	function deployERC1967Proxy(address implementation) internal returns (address) {
		return deployERC1967Proxy(implementation, emptyData());
	}

	function deployERC1967Proxy(address implementation, bytes memory data) internal returns (address) {
		return address(new ERC1967Proxy(implementation, data));
	}

	function deployTransparentUpgradeableProxy(
		string memory name,
		address implementation,
		address owner,
		bytes memory data
	) internal returns (address proxy) {
		vm.label(
			(proxy = deployTransparentUpgradeableProxy(implementation, owner, data)),
			string.concat(name, " Proxy")
		);
	}

	function deployTransparentUpgradeableProxy(
		string memory name,
		address implementation,
		address owner
	) internal returns (address) {
		return deployTransparentUpgradeableProxy(name, implementation, owner, emptyData());
	}

	function deployTransparentUpgradeableProxy(address implementation, address owner) internal returns (address) {
		return deployTransparentUpgradeableProxy(implementation, owner, emptyData());
	}

	function deployTransparentUpgradeableProxy(
		address implementation,
		address owner,
		bytes memory data
	) internal returns (address) {
		return address(new TransparentUpgradeableProxy(implementation, owner, data));
	}

	function getERC1967Implementation(address proxy) internal view returns (address) {
		return vm.load(proxy, ERC1967_IMPLEMENTATION_SLOT).castToAddress();
	}

	function getERC1967Admin(address proxy) internal view returns (address) {
		return vm.load(proxy, ERC1967_ADMIN_SLOT).castToAddress();
	}

	function getERC1967ProxyAdmin(address proxy) internal view returns (ProxyAdmin) {
		return ProxyAdmin(getERC1967Admin(proxy));
	}

	function checkERC1967ImplementationSlot(address proxy, address expected) internal view {
		vm.assertEq(getERC1967Implementation(proxy), expected);
	}

	function emptyData() internal pure returns (bytes calldata data) {
		assembly ("memory-safe") {
			data.length := 0
		}
	}
}
