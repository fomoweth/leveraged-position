// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IConfigurator {
	event AddressSet(bytes32 indexed id, address indexed newAddress);

	event AddressSetAsProxy(bytes32 indexed id, address indexed proxy, address indexed newImplementation);

	function getAddress(bytes32 id) external view returns (address);

	function setAddress(bytes32 id, address newAddress) external;

	function setAddressAsProxy(bytes32 id, address newImplementation) external;

	function getPositionDeployer() external view returns (address);

	function setPositionDeployerImpl(address newImplementation) external;

	function getPositionDescriptor() external view returns (address);

	function setPositionDescriptorImpl(address newImplementation) external;
}
