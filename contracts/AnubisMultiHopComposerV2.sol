// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ILayerZeroComposer } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import { MessagingFee, MessagingReceipt } from
    "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import { IOFT, OFTFeeDetail, OFTLimit, OFTReceipt, SendParam } from
    "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { OFTComposeMsgCodec } from
    "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";

interface IOAppEndpoint {
    function endpoint() external view returns (address);
}

/// @notice Routes a composed OFT receipt on the Ethereum hub into a second OFT hop.
/// @dev Follows the LayerZero/Stargate failure model: protocol-level failures
///      revert for retry; business-level second-hop failures stop on Ethereum,
///      attempt an immediate local refund, and accrue a user claim only if that
///      local refund cannot be delivered. No automatic reverse bridge is attempted.
///      Routes and destinations are owner allowlisted.
contract AnubisMultiHopComposerV2 is ILayerZeroComposer, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint64 public constant OFT_ENCODING_VERSION = 1;
    uint256 private constant NATIVE_REFUND_GAS = 30_000;
    bytes32 private constant TOKEN_REFUND_TYPEHASH = keccak256(
        "TokenRefund(address token,address claimant,address recipient,uint256 amount,uint256 nonce,uint256 deadline)"
    );
    bytes32 private constant NATIVE_REFUND_TYPEHASH = keccak256(
        "NativeRefund(address claimant,address recipient,uint256 amount,uint256 nonce,uint256 deadline)"
    );
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 private constant EIP712_NAME_HASH = keccak256("Anubis MultiHop Composer");
    bytes32 private constant EIP712_VERSION_HASH = keccak256("1");
    bytes4 private constant ERC1271_MAGICVALUE = 0x1626ba7e;

    struct Route {
        address token;
        address nextOft;
        bool enabled;
    }

    struct RouteConfig {
        address sourceOft;
        address token;
        address nextOft;
        bool enabled;
    }

    struct DestinationConfig {
        address nextOft;
        uint32 dstEid;
        bool allowed;
    }

    struct ExecutionContext {
        bytes32 sourceGuid;
        address sourceOft;
        Route route;
        SendParam nextHop;
        address refundAddress;
        uint256 receivedAmount;
    }

    address public immutable endpoint;
    mapping(address sourceOft => Route route) public routes;
    mapping(address nextOft => mapping(uint32 dstEid => bool allowed)) public allowedDestinations;
    mapping(address token => mapping(address account => uint256 amount)) public tokenRefunds;
    mapping(address token => uint256 amount) public totalTokenRefunds;
    mapping(address token => bool) public protectedRouteTokens;
    mapping(address claimant => uint256 nonce) public tokenRefundNonces;
    mapping(address account => uint256 amount) public nativeRefunds;
    uint256 public totalNativeRefunds;
    mapping(address claimant => uint256 nonce) public nativeRefundNonces;

    event RouteSet(address indexed sourceOft, address indexed token, address indexed nextOft, bool enabled);
    event RouteRemoved(address indexed sourceOft);
    event DestinationSet(address indexed nextOft, uint32 indexed dstEid, bool allowed);
    event MultiHopSent(
        bytes32 indexed sourceGuid,
        bytes32 indexed nextGuid,
        address indexed sourceOft,
        address nextOft,
        uint32 dstEid,
        bytes32 recipient,
        uint256 amountSentLD,
        uint256 amountReceivedLD
    );
    event ComposeRefunded(
        bytes32 indexed sourceGuid,
        address indexed token,
        address indexed refundAddress,
        uint256 tokenAmount,
        uint256 nativeAmount,
        bytes reason
    );
    event TokenRefundAccrued(address indexed token, address indexed account, uint256 amount);
    event TokenRefundWithdrawn(address indexed token, address indexed account, uint256 amount);
    event NativeRefundAccrued(address indexed account, uint256 amount);
    event NativeRefundWithdrawn(address indexed account, uint256 amount);
    event TokenRefundWithdrawnTo(
        address indexed token, address indexed claimant, address indexed recipient, uint256 amount
    );
    event NativeRefundWithdrawnTo(address indexed claimant, address indexed recipient, uint256 amount);
    event SurplusRecovered(address indexed token, address indexed to, uint256 amount);
    event NativeSurplusRecovered(address indexed to, uint256 amount);

    error OnlyEndpoint(address caller);
    error OnlySelf(address caller);
    error InvalidRoute(address sourceOft);
    error InvalidRouteConfiguration();
    error InvalidOFT(address oft);
    error DestinationNotAllowed(address nextOft, uint32 dstEid);
    error InvalidPayload();
    error InvalidRecipient();
    error SlippageExceeded(uint256 amountReceivedLD, uint256 minAmountLD);
    error InsufficientNativeFee(uint256 supplied, uint256 required);
    error RefundTransferFailed();
    error InvalidRecoveryAmount();
    error RetryableSecondHopFailure();
    error RefundNotBacked(address token, uint256 balance, uint256 required);

    constructor(address endpoint_, address owner_) Ownable(owner_) {
        if (endpoint_ == address(0) || owner_ == address(0)) revert InvalidRouteConfiguration();
        endpoint = endpoint_;
    }

    receive() external payable {}

    function setRoute(address sourceOft, address token, address nextOft, bool enabled) external onlyOwner {
        _setRoute(sourceOft, token, nextOft, enabled);
    }

    function setRoutes(RouteConfig[] calldata configs) external onlyOwner {
        for (uint256 i; i < configs.length; ++i) {
            RouteConfig calldata config = configs[i];
            _setRoute(config.sourceOft, config.token, config.nextOft, config.enabled);
        }
    }

    function _setRoute(address sourceOft, address token, address nextOft, bool enabled) internal {
        if (sourceOft == address(0) || token == address(0) || nextOft == address(0)) {
            revert InvalidRouteConfiguration();
        }
        // A route token may still be held by the Composer for an unprocessed or
        // retryable compose message after the route is disabled or removed.
        // Keep this marker permanently set so those funds can never be treated
        // as owner-recoverable surplus.
        protectedRouteTokens[token] = true;
        Route memory current = routes[sourceOft];
        bool pureDisable = !enabled && current.token == token && current.nextOft == nextOft;
        if (!pureDisable) {
            _validateOFT(sourceOft, token);
            _validateOFT(nextOft, token);
        }
        routes[sourceOft] = Route(token, nextOft, enabled);
        emit RouteSet(sourceOft, token, nextOft, enabled);
    }

    /// @notice Removes a route without calling either OFT, so a broken integration can always be stopped.
    /// @dev Pending compose messages remain retryable until the route is restored.
    function removeRoute(address sourceOft) external onlyOwner {
        delete routes[sourceOft];
        emit RouteRemoved(sourceOft);
    }

    function _validateOFT(address oft, address expectedToken) internal view {
        try IOFT(oft).token() returns (address actualToken) {
            if (actualToken != expectedToken) revert InvalidOFT(oft);
        } catch {
            revert InvalidOFT(oft);
        }
        try IOFT(oft).oftVersion() returns (bytes4 interfaceId, uint64 version) {
            // Older official OFT implementations can expose a different
            // interface id while remaining message-encoding version 1.
            if (interfaceId == bytes4(0) || version != OFT_ENCODING_VERSION) revert InvalidOFT(oft);
        } catch {
            revert InvalidOFT(oft);
        }
        try IOFT(oft).sharedDecimals() returns (uint8) {} catch {
            revert InvalidOFT(oft);
        }
        try IOFT(oft).approvalRequired() returns (bool) {} catch {
            revert InvalidOFT(oft);
        }
        try IOAppEndpoint(oft).endpoint() returns (address oftEndpoint) {
            if (oftEndpoint != endpoint) revert InvalidOFT(oft);
        } catch {
            revert InvalidOFT(oft);
        }
    }

    function setDestination(address nextOft, uint32 dstEid, bool allowed) external onlyOwner {
        _setDestination(nextOft, dstEid, allowed);
    }

    function setDestinations(DestinationConfig[] calldata configs) external onlyOwner {
        for (uint256 i; i < configs.length; ++i) {
            DestinationConfig calldata config = configs[i];
            _setDestination(config.nextOft, config.dstEid, config.allowed);
        }
    }

    function _setDestination(address nextOft, uint32 dstEid, bool allowed) internal {
        if (nextOft == address(0) || dstEid == 0) revert InvalidRouteConfiguration();
        allowedDestinations[nextOft][dstEid] = allowed;
        emit DestinationSet(nextOft, dstEid, allowed);
    }

    /// @dev The standard lzAsset payload is abi.encode(nextHopParam).
    ///      Keeping the decoder external makes malformed user input catchable.
    function decodePayload(bytes calldata payload) external pure returns (SendParam memory) {
        return abi.decode(payload, (SendParam));
    }

    function lzCompose(
        address from,
        bytes32 guid,
        bytes calldata message,
        address,
        bytes calldata
    ) external payable override nonReentrant {
        if (msg.sender != endpoint) revert OnlyEndpoint(msg.sender);
        _handleCompose(from, guid, message);
    }

    function _handleCompose(address from, bytes32 guid, bytes calldata message) internal {
        Route memory route = routes[from];
        if (route.token == address(0)) revert InvalidRoute(from);
        uint256 receivedAmount = OFTComposeMsgCodec.amountLD(message);
        bytes32 composeFrom = OFTComposeMsgCodec.composeFrom(message);
        address fallbackRefund = _validEvmAddress(composeFrom);
        (bool decoded, SendParam memory nextHop, bytes memory decodeError) =
            _tryDecodePayload(OFTComposeMsgCodec.composeMsg(message));
        if (!decoded) {
            if (fallbackRefund == address(0)) revert InvalidRecipient();
            return _refund(guid, route.token, fallbackRefund, receivedAmount, msg.value, decodeError);
        }
        // nextHop.to is the intended end user and remains available in the
        // standard SendParam even when a router initiated the first hop.
        address refundAddress = _validEvmAddress(nextHop.to);
        if (refundAddress == address(0)) refundAddress = fallbackRefund;
        if (refundAddress == address(0)) revert InvalidRecipient();
        if (!route.enabled) return _refundDisabled(guid, from, route.token, refundAddress, receivedAmount);
        bytes memory validationError = _validatePayload(route.nextOft, nextHop, receivedAmount);
        if (validationError.length != 0) return _refund(guid, route.token, refundAddress, receivedAmount, msg.value, validationError);
        _executeOrRefund(ExecutionContext(guid, from, route, nextHop, refundAddress, receivedAmount));
    }

    function _tryDecodePayload(bytes memory payloadData)
        internal
        view
        returns (bool decoded, SendParam memory payload, bytes memory reason)
    {
        try this.decodePayload(payloadData) returns (SendParam memory value) {
            return (true, value, "");
        } catch (bytes memory errorData) {
            return (false, payload, errorData);
        }
    }

    function _refundDisabled(
        bytes32 guid,
        address sourceOft,
        address token,
        address refundAddress,
        uint256 receivedAmount
    ) internal {
        _refund(
            guid,
            token,
            refundAddress,
            receivedAmount,
            msg.value,
            abi.encodeWithSelector(InvalidRoute.selector, sourceOft)
        );
    }

    function _executeOrRefund(ExecutionContext memory context) internal {
        try this.executeSecondHop{ value: msg.value }(
            context.route, context.nextHop, context.receivedAmount
        )
            returns (bytes32 nextGuid, OFTReceipt memory oftReceipt, uint256 nativeFee)
        {
            _refund(
                context.sourceGuid,
                context.route.token,
                context.refundAddress,
                context.receivedAmount - oftReceipt.amountSentLD,
                msg.value - nativeFee,
                ""
            );
            emit MultiHopSent(
                context.sourceGuid,
                nextGuid,
                context.sourceOft,
                context.route.nextOft,
                context.nextHop.dstEid,
                context.nextHop.to,
                oftReceipt.amountSentLD,
                oftReceipt.amountReceivedLD
            );
        } catch (bytes memory reason) {
            // lzCompose is permissionless. Caller-controlled fee or gas must never be able to
            // consume a valid message by forcing the local-refund branch.
            if (reason.length == 0) revert RetryableSecondHopFailure();
            if (bytes4(reason) == InsufficientNativeFee.selector) {
                assembly {
                    revert(add(reason, 32), mload(reason))
                }
            }
            _refund(
                context.sourceGuid,
                context.route.token,
                context.refundAddress,
                context.receivedAmount,
                msg.value,
                reason
            );
        }
    }

    function _validatePayload(address nextOft, SendParam memory nextHop, uint256 receivedAmount)
        internal
        view
        returns (bytes memory)
    {
        if (!allowedDestinations[nextOft][nextHop.dstEid]) {
            return abi.encodeWithSelector(DestinationNotAllowed.selector, nextOft, nextHop.dstEid);
        }
        if (nextHop.to == bytes32(0)) return abi.encodeWithSelector(InvalidRecipient.selector);
        SendParam memory quotedParam = nextHop;
        quotedParam.amountLD = receivedAmount;
        try IOFT(nextOft).quoteOFT(quotedParam) returns (OFTLimit memory, OFTFeeDetail[] memory, OFTReceipt memory receipt) {
            if (receipt.amountReceivedLD < nextHop.minAmountLD) {
                return abi.encodeWithSelector(
                    SlippageExceeded.selector, receipt.amountReceivedLD, nextHop.minAmountLD
                );
            }
        } catch (bytes memory reason) {
            return reason.length == 0 ? abi.encodeWithSelector(InvalidPayload.selector) : reason;
        }
        return "";
    }

    function _validEvmAddress(bytes32 value) internal pure returns (address) {
        if (uint256(value) >> 160 != 0) return address(0);
        return address(uint160(uint256(value)));
    }

    /// @dev Called only through an external self-call so every second-hop side effect
    ///      (including approvals) rolls back atomically and can be caught by lzCompose.
    function executeSecondHop(Route calldata route, SendParam calldata userParam, uint256 receivedAmount)
        external
        payable
        returns (bytes32 nextGuid, OFTReceipt memory oftReceipt, uint256 nativeFee)
    {
        if (msg.sender != address(this)) revert OnlySelf(msg.sender);

        SendParam memory nextHop = userParam;
        nextHop.amountLD = receivedAmount;
        if (IOFT(route.nextOft).approvalRequired()) IERC20(route.token).forceApprove(route.nextOft, receivedAmount);

        MessagingFee memory fee = IOFT(route.nextOft).quoteSend(nextHop, false);
        if (msg.value < fee.nativeFee) revert InsufficientNativeFee(msg.value, fee.nativeFee);

        MessagingReceipt memory receipt;
        (receipt, oftReceipt) = IOFT(route.nextOft).send{ value: fee.nativeFee }(nextHop, fee, address(this));
        if (oftReceipt.amountSentLD > receivedAmount || oftReceipt.amountReceivedLD < nextHop.minAmountLD) {
            revert SlippageExceeded(oftReceipt.amountReceivedLD, nextHop.minAmountLD);
        }

        if (IOFT(route.nextOft).approvalRequired()) IERC20(route.token).forceApprove(route.nextOft, 0);
        return (receipt.guid, oftReceipt, receipt.fee.nativeFee);
    }

    function _refund(
        bytes32 guid,
        address token,
        address refundAddress,
        uint256 tokenAmount,
        uint256 nativeAmount,
        bytes memory reason
    ) internal {
        if (refundAddress == address(0)) revert InvalidRecipient();
        bool tokenPaid = tokenAmount == 0 || _tryTokenTransfer(token, refundAddress, tokenAmount);
        if (!tokenPaid) {
            uint256 required = totalTokenRefunds[token] + tokenAmount;
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance < required) revert RefundNotBacked(token, balance, required);
            tokenRefunds[token][refundAddress] += tokenAmount;
            totalTokenRefunds[token] += tokenAmount;
            emit TokenRefundAccrued(token, refundAddress, tokenAmount);
        }

        bool nativePaid = nativeAmount == 0 || _tryNativeTransfer(refundAddress, nativeAmount);
        if (!nativePaid) {
            nativeRefunds[refundAddress] += nativeAmount;
            totalNativeRefunds += nativeAmount;
            emit NativeRefundAccrued(refundAddress, nativeAmount);
        }

        if (tokenAmount != 0 || nativeAmount != 0 || reason.length != 0) {
            emit ComposeRefunded(guid, token, refundAddress, tokenAmount, nativeAmount, reason);
        }
    }

    function _tryTokenTransfer(address token, address to, uint256 amount) internal returns (bool) {
        if (to == address(0)) return false;
        return IERC20(token).trySafeTransfer(to, amount);
    }

    function _tryNativeTransfer(address to, uint256 amount) internal returns (bool) {
        if (to == address(0)) return false;
        (bool ok,) = payable(to).call{ value: amount, gas: NATIVE_REFUND_GAS }("");
        return ok;
    }

    function withdrawTokenRefund(address token) external nonReentrant {
        _withdrawTokenRefund(token, msg.sender, msg.sender);
    }

    /// @notice Withdraw a token refund to an alternate recipient authorized by the claimant.
    /// @dev Supports EOAs and ERC-1271 contract accounts through SignatureChecker.
    function withdrawTokenRefundTo(
        address token,
        address claimant,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external nonReentrant {
        if (recipient == address(0) || block.timestamp > deadline) revert InvalidRecipient();
        uint256 amount = tokenRefunds[token][claimant];
        uint256 nonce = tokenRefundNonces[claimant];
        bytes32 digest = _hashRefundTypedData(
            keccak256(abi.encode(TOKEN_REFUND_TYPEHASH, token, claimant, recipient, amount, nonce, deadline))
        );
        if (!_isValidSignature(claimant, digest, signature)) revert InvalidRecipient();
        tokenRefundNonces[claimant] = nonce + 1;
        _withdrawTokenRefund(token, claimant, recipient);
        emit TokenRefundWithdrawnTo(token, claimant, recipient, amount);
    }

    function _withdrawTokenRefund(address token, address claimant, address recipient) internal {
        uint256 amount = tokenRefunds[token][claimant];
        tokenRefunds[token][claimant] = 0;
        totalTokenRefunds[token] -= amount;
        IERC20(token).safeTransfer(recipient, amount);
        emit TokenRefundWithdrawn(token, claimant, amount);
    }

    function withdrawNativeRefund() external nonReentrant {
        _withdrawNativeRefund(msg.sender, payable(msg.sender));
    }

    /// @notice Withdraw a native refund to an alternate recipient authorized by the claimant.
    /// @dev Supports EOAs and ERC-1271 contract accounts through SignatureChecker.
    function withdrawNativeRefundTo(
        address claimant,
        address payable recipient,
        uint256 deadline,
        bytes calldata signature
    ) external nonReentrant {
        if (recipient == address(0) || block.timestamp > deadline) revert InvalidRecipient();
        uint256 amount = nativeRefunds[claimant];
        uint256 nonce = nativeRefundNonces[claimant];
        bytes32 digest = _hashRefundTypedData(
            keccak256(abi.encode(NATIVE_REFUND_TYPEHASH, claimant, recipient, amount, nonce, deadline))
        );
        if (!_isValidSignature(claimant, digest, signature)) revert InvalidRecipient();
        nativeRefundNonces[claimant] = nonce + 1;
        _withdrawNativeRefund(claimant, recipient);
        emit NativeRefundWithdrawnTo(claimant, recipient, amount);
    }

    function _withdrawNativeRefund(address claimant, address payable recipient) internal {
        uint256 amount = nativeRefunds[claimant];
        nativeRefunds[claimant] = 0;
        totalNativeRefunds -= amount;
        (bool ok,) = recipient.call{ value: amount }("");
        if (!ok) revert RefundTransferFailed();
        emit NativeRefundWithdrawn(claimant, amount);
    }

    function _hashRefundTypedData(bytes32 structHash) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                EIP712_NAME_HASH,
                EIP712_VERSION_HASH,
                block.chainid,
                address(this)
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function _isValidSignature(address signer, bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        if (signer.code.length != 0) {
            (bool ok, bytes memory result) = signer.staticcall(
                abi.encodeWithSignature("isValidSignature(bytes32,bytes)", digest, signature)
            );
            return ok && result.length >= 4 && bytes4(result) == ERC1271_MAGICVALUE;
        }
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
                v := byte(0, mload(add(signature, 96)))
            }
            if (v < 27) v += 27;
            return v == 27 || v == 28 ? ecrecover(digest, v, r, s) == signer : false;
        }
        if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 32))
                vs := mload(add(signature, 64))
            }
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            uint8 v = uint8(uint256(vs >> 255)) + 27;
            return ecrecover(digest, v, r, s) == signer;
        }
        return false;
    }

    function recoverSurplus(address token, address to, uint256 amount) external onlyOwner nonReentrant {
        if (
            to == address(0) || protectedRouteTokens[token]
                || IERC20(token).balanceOf(address(this)) < totalTokenRefunds[token] + amount
        ) {
            revert InvalidRecoveryAmount();
        }
        IERC20(token).safeTransfer(to, amount);
        emit SurplusRecovered(token, to, amount);
    }

    function recoverNativeSurplus(address payable to, uint256 amount) external onlyOwner nonReentrant {
        if (to == address(0) || address(this).balance < totalNativeRefunds + amount) revert InvalidRecoveryAmount();
        (bool ok,) = to.call{ value: amount }("");
        if (!ok) revert RefundTransferFailed();
        emit NativeSurplusRecovered(to, amount);
    }
}
