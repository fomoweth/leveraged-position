// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Errors} from "src/libraries/Errors.sol";
import {Validations} from "./Validations.sol";

/// @title Authority
/// @notice Authorizes msg.sender of calls made to this contract

abstract contract Authority is Validations {
	address internal immutable self = address(this);

	modifier checkDelegateCall() {
		_checkDelegateCall();
		_;
	}

	modifier noDelegateCall() {
		_checkNotDelegateCall();
		_;
	}

	modifier authorized() {
		_checkAuthority();
		_;
	}

	function _checkDelegateCall() private view {
		required(self != address(this), Errors.NotDelegateCall.selector);
	}

	function _checkNotDelegateCall() private view {
		required(self == address(this), Errors.NoDelegateCall.selector);
	}

	function _checkAuthority() private view {
		required(isAuthorized(msg.sender), Errors.Unauthorized.selector);
	}

	function isAuthorized(address account) internal view virtual returns (bool);
}
