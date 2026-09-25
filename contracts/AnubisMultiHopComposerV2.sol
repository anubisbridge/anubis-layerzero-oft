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
    mapping(address account => uint256 amount) public nativeRefunds;
    uint256 public totalNativeRefunds;

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
        (bool ok, bytes memory data) = token.call(abi.encodeCall(IERC20.transfer, (to, amount)));
        return ok && (data.length == 0 || (data.length == 32 && abi.decode(data, (bool))));
    }

    function _tryNativeTransfer(address to, uint256 amount) internal returns (bool) {
        if (to == address(0)) return false;
        (bool ok,) = payable(to).call{ value: amount, gas: NATIVE_REFUND_GAS }("");
        return ok;
    }

    function withdrawTokenRefund(address token) external nonReentrant {
        uint256 amount = tokenRefunds[token][msg.sender];
        tokenRefunds[token][msg.sender] = 0;
        totalTokenRefunds[token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit TokenRefundWithdrawn(token, msg.sender, amount);
    }

    function withdrawNativeRefund() external nonReentrant {
        uint256 amount = nativeRefunds[msg.sender];
        nativeRefunds[msg.sender] = 0;
        totalNativeRefunds -= amount;
        (bool ok,) = payable(msg.sender).call{ value: amount }("");
        if (!ok) revert RefundTransferFailed();
        emit NativeRefundWithdrawn(msg.sender, amount);
    }

    function recoverSurplus(address token, address to, uint256 amount) external onlyOwner nonReentrant {
        if (to == address(0) || IERC20(token).balanceOf(address(this)) < totalTokenRefunds[token] + amount) {
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
