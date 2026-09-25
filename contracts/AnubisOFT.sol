// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Shared Anubis OFT implementation supporting both EndpointV2 fee modes.
/// @dev Reads nativeToken() for every send so the contracts remain compatible
/// if the existing Anubis endpoint switches between ERC20 and native fees.
abstract contract AnubisOFT is OFT {
    using SafeERC20 for IERC20;

    error UnexpectedNativeValue(uint256 supplied);
    error IncorrectNativeFee(uint256 supplied, uint256 required);

    constructor(string memory name_, string memory symbol_, address endpoint_, address delegate_)
        OFT(name_, symbol_, endpoint_, delegate_)
        Ownable(delegate_)
    {}

    function _payNative(uint256 nativeFee) internal virtual override returns (uint256) {
        address feeToken = endpoint.nativeToken();

        if (feeToken == address(0)) {
            if (msg.value != nativeFee) revert IncorrectNativeFee(msg.value, nativeFee);
            return nativeFee;
        }

        if (msg.value != 0) revert UnexpectedNativeValue(msg.value);
        IERC20(feeToken).safeTransferFrom(msg.sender, address(endpoint), nativeFee);
        return 0;
    }
}
