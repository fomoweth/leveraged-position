// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Errors} from "src/libraries/Errors.sol";

/// @title Authority
/// @notice Authorizes msg.sender of calls made to this contract

abstract contract Authority {
	using Errors for bytes4;

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
		Errors.NotDelegateCall.selector.required(self != address(this));
	}

	function _checkNotDelegateCall() private view {
		Errors.NoDelegateCall.selector.required(self == address(this));
	}

	function _checkAuthority() private view {
		Errors.Unauthorized.selector.required(isAuthorized(msg.sender));
	}

	function isAuthorized(address account) internal view virtual returns (bool);
}
