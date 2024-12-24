// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Errors} from "src/libraries/Errors.sol";
import {Currency} from "src/types/Currency.sol";
import {AaveV3Lender} from "src/modules/AaveV3Lender.sol";
import {Configurator} from "src/Configurator.sol";
import {PositionDeployer} from "src/PositionDeployer.sol";
import {PositionDescriptor} from "src/PositionDescriptor.sol";

import {Bytes32Cast} from "test/shared/utils/Bytes32Cast.sol";
import {BaseTest} from "test/shared/BaseTest.sol";

// forge test --match-path test/Configurator.t.sol --chain 1 -vv

contract ConfiguratorTest is BaseTest {
	using Bytes32Cast for bytes32;

	event AddressSet(bytes32 indexed id, address indexed newAddress);

	event AddressSetAsProxy(bytes32 indexed id, address indexed proxy, address indexed newImplementation);

	bytes32 internal constant ADDRESSES_SLOT = 0x67c14ec595f48137cacef9bcaa1219f029491ada758d8ab6d68d9a5281ed279c;

	bytes32 internal constant LAST_REVISION_SLOT = 0x2dcf4d2fa80344eb3d0178ea773deb29f1742cf017431f9ee326c624f742669b;

	bytes32 internal constant POSITION_DEPLOYER = "POSITION_DEPLOYER";
	bytes32 internal constant POSITION_DESCRIPTOR = "POSITION_DESCRIPTOR";

	Configurator internal configurator;

	address internal v1DeployerImpl;
	address internal v2DeployerImpl;
	address internal deployer;

	address internal descriptorImpl;
	address internal descriptor;

	address internal v1Impl;
	address internal v2Impl;
	address internal adapter;

	address internal immutable admin = makeAddr("Admin");

	function setUp() public virtual override {
		super.setUp();

		configurator = new Configurator(admin);

		v1DeployerImpl = address(new PositionDeployer());
		v2DeployerImpl = address(new PositionDeployer());

		descriptorImpl = address(new PositionDescriptor());

		v1Impl = address(
			new AaveV3Lender(aaveV3.id, address(aaveV3.pool), address(aaveV3.oracle), address(aaveV3.rewardsController))
		);

		v2Impl = address(
			new AaveV3Lender(aaveV3.id, address(aaveV3.pool), address(aaveV3.oracle), address(aaveV3.rewardsController))
		);
	}

	function configure() internal virtual override {
		super.configure();
		configureAaveV3("aave");
	}

	function test_deployment() public {
		vm.expectRevert(Errors.InvalidNewOwner.selector);
		new Configurator(address(0));

		assertEq(configurator.owner(), admin);

		vm.expectRevert(Errors.Unauthorized.selector);
		configurator.transferOwnership(address(this));

		vm.prank(admin);
		configurator.transferOwnership(address(this));
		assertEq(configurator.owner(), address(this));

		vm.expectRevert(Errors.InvalidNewOwner.selector);
		configurator.transferOwnership(address(0));

		configurator.renounceOwnership();
		assertEq(configurator.owner(), address(0));
	}

	function test_setAddress_revertsWithUnauthorized() public {
		vm.expectRevert(Errors.Unauthorized.selector);
		configurator.setAddress(aaveV3.id, v1Impl);
	}

	function test_setAddress() public {
		vm.expectRevert(Errors.AddressNotSet.selector);
		configurator.getAddress(aaveV3.id);

		vm.startPrank(admin);

		expectEmitAddressSet(aaveV3.id, v1Impl);
		configurator.setAddress(aaveV3.id, v1Impl);
		assertEq(configurator.getAddress(aaveV3.id), v1Impl);

		expectEmitAddressSet(aaveV3.id, v2Impl);
		configurator.setAddress(aaveV3.id, v2Impl);
		assertEq(configurator.getAddress(aaveV3.id), v2Impl);

		expectEmitAddressSet(aaveV3.id, address(0));
		configurator.setAddress(aaveV3.id, address(0));
		assertEq(getAddress(aaveV3.id), address(0));

		vm.stopPrank();
	}

	function test_setAddressAsProxy_revertsWithUnauthorized() public {
		vm.expectRevert(Errors.Unauthorized.selector);
		configurator.setAddressAsProxy(aaveV3.id, v1Impl);
	}

	function test_setAddressAsProxy() public {
		assertEq(getAddress(aaveV3.id), address(0));
		assertEq(getImplementation(aaveV3.id), address(0));

		vm.startPrank(admin);

		// expectEmitAddressSetAsProxy(aaveV3.id, adapter, v1Impl);
		configurator.setAddressAsProxy(aaveV3.id, v1Impl);

		assertNotEq((adapter = configurator.getAddress(aaveV3.id)), address(0));
		assertEq(getImplementation(aaveV3.id), v1Impl);
		assertEq(getRevision(adapter), 1);

		expectEmitAddressSetAsProxy(aaveV3.id, adapter, v2Impl);
		configurator.setAddressAsProxy(aaveV3.id, v2Impl);

		assertEq(configurator.getAddress(aaveV3.id), adapter);
		assertEq(getImplementation(aaveV3.id), v2Impl);
		assertEq(getRevision(adapter), 2);

		vm.stopPrank();
	}

	function test_setPositionDeployerImpl_revertsWithUnauthorized() public {
		vm.expectRevert(Errors.Unauthorized.selector);
		configurator.setPositionDeployerImpl(v1DeployerImpl);
	}

	function test_setPositionDeployerImpl() public {
		assertEq(getAddress(POSITION_DEPLOYER), address(0));
		assertEq(getImplementation(POSITION_DEPLOYER), address(0));

		vm.expectRevert(Errors.AddressNotSet.selector);
		configurator.getPositionDeployer();

		vm.startPrank(admin);

		configurator.setPositionDeployerImpl(v1DeployerImpl);

		assertNotEq((deployer = configurator.getPositionDeployer()), address(0));
		assertEq(getImplementation(POSITION_DEPLOYER), v1DeployerImpl);
		assertEq(getRevision(deployer), 1);

		expectEmitAddressSetAsProxy(POSITION_DEPLOYER, deployer, v2DeployerImpl);
		configurator.setPositionDeployerImpl(v2DeployerImpl);

		assertEq(configurator.getPositionDeployer(), deployer);
		assertEq(getImplementation(POSITION_DEPLOYER), v2DeployerImpl);
		assertEq(getRevision(deployer), 2);

		vm.stopPrank();
	}

	function test_setPositionDescriptorImpl_revertsWithUnauthorized() public {
		vm.expectRevert(Errors.Unauthorized.selector);
		configurator.setPositionDescriptorImpl(descriptorImpl);
	}

	function test_setPositionDescriptorImpl() public {
		assertEq(getAddress(POSITION_DESCRIPTOR), address(0));
		assertEq(getImplementation(POSITION_DESCRIPTOR), address(0));

		vm.expectRevert(Errors.AddressNotSet.selector);
		configurator.getPositionDescriptor();

		vm.startPrank(admin);

		configurator.setPositionDescriptorImpl(descriptorImpl);

		assertNotEq((descriptor = configurator.getPositionDescriptor()), address(0));
		assertEq(getImplementation(POSITION_DESCRIPTOR), descriptorImpl);
		assertEq(getRevision(descriptor), 1);

		vm.stopPrank();
	}

	function expectEmitAddressSet(bytes32 id, address newAddress) internal {
		vm.expectEmit(true, true, true, true);
		emit AddressSet(id, newAddress);
	}

	function expectEmitAddressSetAsProxy(bytes32 id, address proxy, address newImplementation) internal {
		vm.expectEmit(true, true, true, true);
		emit AddressSetAsProxy(id, proxy, newImplementation);
	}

	function getAddress(bytes32 slot, bytes32 id) internal view returns (address) {
		return vm.load(address(configurator), encodeSlot(slot, id)).castToAddress();
	}

	function getAddress(bytes32 id) internal view returns (address) {
		return getAddress(ADDRESSES_SLOT, id);
	}

	function getImplementation(bytes32 id) internal view returns (address) {
		return getAddress(ERC1967_IMPLEMENTATION_SLOT, id);
	}

	function getRevision(address target) internal view returns (uint64) {
		return vm.load(target, LAST_REVISION_SLOT).castToUint64();
	}
}
