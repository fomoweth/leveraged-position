// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IPermit2 {
	error AllowanceExpired(uint256 deadline);

	error InsufficientAllowance(uint256 amount);

	error ExcessiveInvalidation();

	error InvalidAmount(uint256 maxAmount);

	error LengthMismatch();

	event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

	event NonceInvalidation(
		address indexed owner,
		address indexed token,
		address indexed spender,
		uint48 newNonce,
		uint48 oldNonce
	);

	event Approval(
		address indexed owner,
		address indexed token,
		address indexed spender,
		uint160 amount,
		uint48 expiration
	);

	event Permit(
		address indexed owner,
		address indexed token,
		address indexed spender,
		uint160 amount,
		uint48 expiration,
		uint48 nonce
	);

	event Lockdown(address indexed owner, address token, address spender);

	struct PermitDetails {
		address token;
		uint160 amount;
		uint48 expiration;
		uint48 nonce;
	}

	struct PermitSingle {
		PermitDetails details;
		address spender;
		uint256 sigDeadline;
	}

	struct PermitBatch {
		PermitDetails[] details;
		address spender;
		uint256 sigDeadline;
	}

	struct PackedAllowance {
		uint160 amount;
		uint48 expiration;
		uint48 nonce;
	}

	struct TokenSpenderPair {
		address token;
		address spender;
	}

	struct AllowanceTransferDetails {
		address from;
		address to;
		uint160 amount;
		address token;
	}

	struct TokenPermissions {
		address token;
		uint256 amount;
	}

	struct PermitTransferFrom {
		TokenPermissions permitted;
		uint256 nonce;
		uint256 deadline;
	}

	struct SignatureTransferDetails {
		address to;
		uint256 requestedAmount;
	}

	struct PermitBatchTransferFrom {
		TokenPermissions[] permitted;
		uint256 nonce;
		uint256 deadline;
	}

	// IAllowanceTransfer

	function allowance(
		address user,
		address token,
		address spender
	) external view returns (uint160 amount, uint48 expiration, uint48 nonce);

	function approve(address token, address spender, uint160 amount, uint48 expiration) external;

	function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

	function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

	function transferFrom(address from, address to, uint160 amount, address token) external;

	function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

	function lockdown(TokenSpenderPair[] calldata approvals) external;

	function invalidateNonces(address token, address spender, uint48 newNonce) external;

	// ISignatureTransfer

	function nonceBitmap(address, uint256) external view returns (uint256);

	function permitTransferFrom(
		PermitTransferFrom memory permit,
		SignatureTransferDetails calldata transferDetails,
		address owner,
		bytes calldata signature
	) external;

	function permitWitnessTransferFrom(
		PermitTransferFrom memory permit,
		SignatureTransferDetails calldata transferDetails,
		address owner,
		bytes32 witness,
		string calldata witnessTypeString,
		bytes calldata signature
	) external;

	function permitTransferFrom(
		PermitBatchTransferFrom memory permit,
		SignatureTransferDetails[] calldata transferDetails,
		address owner,
		bytes calldata signature
	) external;

	function permitWitnessTransferFrom(
		PermitBatchTransferFrom memory permit,
		SignatureTransferDetails[] calldata transferDetails,
		address owner,
		bytes32 witness,
		string calldata witnessTypeString,
		bytes calldata signature
	) external;

	function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;

	// IEIP712

	function DOMAIN_SEPARATOR() external view returns (bytes32);
}
