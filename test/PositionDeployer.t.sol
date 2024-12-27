// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Errors} from "src/libraries/Errors.sol";
import {Currency} from "src/types/Currency.sol";
import {Configurator} from "src/Configurator.sol";
import {AaveV3Lender} from "src/modules/AaveV3Lender.sol";
import {LeveragedPosition} from "src/LeveragedPosition.sol";
import {PositionDeployer} from "src/PositionDeployer.sol";

import {BaseTest} from "test/shared/BaseTest.sol";

// forge test --match-path test/PositionDeployer.t.sol --chain 1 -vv

contract PositionDeployerTest is BaseTest {
	string internal constant AAVE_V3_AAVE_KEY = "aave";
	bytes32 internal constant AAVE_V3_AAVE_ID = "AAVE-V3: Aave";

	Configurator internal configurator;

	PositionDeployer internal deployer;

	address internal owner = address(this);
	address internal lender;

	bytes internal creationCode = type(LeveragedPosition).creationCode;
	bytes internal constructorParams;
	bytes internal parameters;

	function setUp() public virtual override {
		super.setUp();

		configurator = new Configurator(address(this));
		configurator.setPositionDeployerImpl(address(new PositionDeployer()));

		deployer = PositionDeployer(configurator.getPositionDeployer());

		configurator.setAddress(
			AAVE_V3_AAVE_ID,
			lender = address(
				new AaveV3Lender(
					AAVE_V3_AAVE_ID,
					address(aaveV3.pool),
					address(aaveV3.oracle),
					address(aaveV3.rewardsController)
				)
			)
		);

		constructorParams = abi.encode(lender, WETH, USDC);
		parameters = abi.encode(creationCode, constructorParams);
	}

	function configure() internal virtual override {
		super.configure();

		configureAaveV3(AAVE_V3_AAVE_KEY);
	}

	function test_deployPosition_failsWithInvalidParameters() public {
		vm.expectRevert(Errors.EmptyCreationCode.selector);
		deployer.deployPosition(abi.encode(emptyData(), emptyData()));

		vm.expectRevert(Errors.EmptyConstructor.selector);
		deployer.deployPosition(abi.encode(creationCode, emptyData()));

		vm.expectRevert(Errors.EmptyCreationCode.selector);
		deployer.deployPosition(abi.encode(emptyData(), constructorParams));
	}

	function test_deployPosition_succeedsWithValidParameters() public {
		verifyPosition(LeveragedPosition(deployer.deployPosition(parameters)), 0);
	}

	function test_deployPosition_succeedsForMultiplePositionsWithSameSalt() public {
		for (uint256 i; i < 6; ++i) {
			verifyPosition(LeveragedPosition(deployer.deployPosition(parameters)), i);
		}
	}

	function verifyPosition(LeveragedPosition position, uint256 nonce) internal view {
		assertEq(position.OWNER(), owner, "!owner");
		assertEq(position.LENDER(), lender, "!lender");
		assertEq(position.COLLATERAL_ASSET(), WETH, "!collateralAsset");
		assertEq(position.LIABILITY_ASSET(), USDC, "!liabilityAsset");

		bytes32 salt = bytes32(uint256(keccak256(abi.encode(owner, lender, WETH, USDC))) + nonce);
		assertEq(address(position), deployer.getPosition(salt));
		assertEq(address(position), deployer.getPosition(owner, lender, WETH, USDC, nonce));
	}
}
