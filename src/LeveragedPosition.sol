// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILender} from "src/interfaces/ILender.sol";
import {MASK_160_BITS, MASK_128_BITS, MASK_104_BITS, MASK_80_BITS, MASK_40_BITS, MASK_16_BITS, MASK_8_BITS} from "src/libraries/BitMasks.sol";
import {Errors} from "src/libraries/Errors.sol";
import {Math} from "src/libraries/Math.sol";
import {Path} from "src/libraries/Path.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {StorageSlot} from "src/libraries/StorageSlot.sol";
import {TypeConversion} from "src/libraries/TypeConversion.sol";
import {Currency} from "src/types/Currency.sol";
import {Authority} from "src/base/Authority.sol";
import {Chain} from "src/base/Chain.sol";
import {Dispatcher} from "src/base/Dispatcher.sol";

/// @title LeveragedPosition

contract LeveragedPosition is Authority, Dispatcher {
	using Math for uint256;
	using Path for bytes;
	using PercentageMath for uint256;
	using SafeCast for uint256;
	using StorageSlot for bytes32;
	using TypeConversion for bytes32;
	using TypeConversion for uint256;

	/// bytes32(uint256(keccak256("CachedStates")) - 1)
	bytes32 internal constant CACHED_STATES_SLOT = 0xbccfadcee7b0732cf801848fc4efcf23fc7b691eead903e5750a9a818b768920;

	/// bytes32(uint256(keccak256("Checkpoints")) - 1)
	bytes32 internal constant CHECKPOINTS_SLOT = 0xeded99094b44ca9eb47e05613fb3034bde089727218b718bf410858d557d0649;

	/// bytes32(uint256(keccak256("Liquidity")) - 1)
	bytes32 internal constant LIQUIDITY_SLOT = 0xf635637ba62fd05a8c192160221386e8a7a4f08458b93e1a9885a356979e4200;

	/// bytes32(uint256(keccak256("LoanToValueBounds")) - 1)
	bytes32 internal constant LTV_BOUNDS_SLOT = 0xf44fb122107512ba249743c2468120cbe34f13a1b438b749d63480d1c4312fb6;

	/// bytes32(uint256(keccak256("Principals")) - 1)
	bytes32 internal constant PRINCIPALS_SLOT = 0x5bb3b7ca8bab030a7bd3d8edb241987b90077c22b12fa059a01004242b2ac5fd;

	bytes32 internal constant ACTION_KEY = "ACTION";
	bytes32 internal constant COLLATERAL_KEY = "COLLATERAL";
	bytes32 internal constant LIABILITY_KEY = "LIABILITY";

	bytes32 internal constant INCREASE_LIQUIDITY_ACTION = "INCREASE_LIQUIDITY";
	bytes32 internal constant DECREASE_LIQUIDITY_ACTION = "DECREASE_LIQUIDITY";

	uint8 internal constant COLLATERAL_SIDE = 1;
	uint8 internal constant LIABILITY_SIDE = 2;

	address public immutable owner;
	address public immutable lender;
	Currency public immutable collateralAsset;
	Currency public immutable liabilityAsset;

	uint64 internal immutable collateralScale;
	uint64 internal immutable liabilityScale;

	constructor(address _owner, address _lender, Currency _collateralAsset, Currency _liabilityAsset) {
		owner = _owner;
		lender = _lender;
		collateralAsset = _collateralAsset;
		liabilityAsset = _liabilityAsset;
		collateralScale = uint64(10 ** _collateralAsset.decimals());
		liabilityScale = uint64(10 ** _liabilityAsset.decimals());
	}

	function setLtvBounds(uint256 upperBound, uint256 lowerBound) external authorized {}

	function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata path) external {}

	function increaseLiquidity(bytes calldata params) external payable authorized {}

	function decreaseLiquidity(bytes calldata params) external payable authorized {}

	function claimRewards(address recipient) external payable authorized {}

	function sweep(Currency currency) external payable authorized {
		uint256 balance = currency.balanceOfSelf();
		if (balance == 0) return;

		currency.transfer(msg.sender, balance);
	}

	function supplyInternal(uint256 amount) internal virtual {
		bytes memory data = abi.encodeCall(ILender.supply, (collateralAsset, amount));
		updateLiquidity(collateralAsset, abi.decode(dispatch(lender, data), (int256)), COLLATERAL_SIDE);
	}

	function borrowInternal(uint256 amount) internal virtual {
		bytes memory data = abi.encodeCall(ILender.borrow, (liabilityAsset, amount));
		updateLiquidity(liabilityAsset, abi.decode(dispatch(lender, data), (int256)), LIABILITY_SIDE);
	}

	function repayInternal(uint256 amount) internal virtual {
		bytes memory data = abi.encodeCall(ILender.repay, (liabilityAsset, amount));
		updateLiquidity(liabilityAsset, abi.decode(dispatch(lender, data), (int256)), LIABILITY_SIDE);
	}

	function redeemInternal(uint256 amount) internal virtual {
		bytes memory data = abi.encodeCall(ILender.redeem, (collateralAsset, amount));
		updateLiquidity(collateralAsset, abi.decode(dispatch(lender, data), (int256)), COLLATERAL_SIDE);
	}

	function claimInternal(address recipient) internal virtual {
		dispatch(lender, abi.encodeCall(ILender.claim, (recipient)));
	}

	function updateLiquidity(Currency currency, int256 delta, uint8 side) internal virtual {
		bytes32 derivedSlot = LIQUIDITY_SLOT.deriveMapping(currency.toId());

		assembly ("memory-safe") {
			sstore(
				derivedSlot,
				or(
					add(
						shl(248, and(MASK_8_BITS, side)),
						add(shl(208, and(MASK_40_BITS, shr(208, delta))), shl(104, and(MASK_104_BITS, shr(104, delta))))
					),
					and(MASK_104_BITS, add(signextend(12, sload(derivedSlot)), signextend(12, delta)))
				)
			)
		}
	}

	function getPositionCollateral() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getAccountCollateral, (collateralAsset, address(this)));
		return abi.decode(fetch(lender, data), (uint256));
	}

	function getPositionLiability() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getAccountLiability, (liabilityAsset, address(this)));
		return abi.decode(fetch(lender, data), (uint256));
	}

	function getAvailableLiquidity() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getAvailableLiquidity, (liabilityAsset));
		return abi.decode(fetch(lender, data), (uint256));
	}

	function getCollateralFactor() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getCollateralFactor, (collateralAsset));
		return abi.decode(fetch(lender, data), (uint256));
	}

	function getLiquidationFactor() internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getLiquidationFactor, (collateralAsset));
		return abi.decode(fetch(lender, data), (uint256));
	}

	function getPrice(Currency currency) internal view virtual returns (uint256) {
		bytes memory data = abi.encodeCall(ILender.getPrice, (currency));
		return abi.decode(fetch(lender, data), (uint256));
	}

	function getRatio(Currency currency) internal view virtual returns (uint256) {
		return abi.decode(fetch(lender, abi.encodeCall(ILender.getRatio, (currency))), (uint256));
	}

	function isAuthorized(address account) internal view virtual override returns (bool) {
		return account == owner;
	}

	function isValidAction(bytes32 action) internal view virtual returns (bool) {
		return action == INCREASE_LIQUIDITY_ACTION || action == DECREASE_LIQUIDITY_ACTION;
	}

	function cache(bytes32 key) internal pure virtual returns (bytes32) {
		return CACHED_STATES_SLOT.deriveMapping(key);
	}

	function version() external pure virtual returns (uint64) {
		return 1;
	}
}
