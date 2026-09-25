// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IOFT, OFTFeeDetail, OFTLimit, OFTReceipt, SendParam } from
    "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee, MessagingReceipt } from
    "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import { ILayerZeroComposer } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";

contract MockComposerToken is IERC20 {
    string public constant name = "Mock";
    string public constant symbol = "MOCK";
    uint8 public constant decimals = 6;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => bool) public blocked;

    function mint(address to, uint256 amount) external { balanceOf[to] += amount; totalSupply += amount; }
    function setBlocked(address account, bool value) external { blocked[account] = value; }
    function approve(address spender, uint256 amount) external override returns (bool) { allowance[msg.sender][spender] = amount; return true; }
    function transfer(address to, uint256 amount) external override returns (bool) { _transfer(msg.sender, to, amount); return true; }
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");
        allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(!blocked[to], "blocked");
        require(balanceOf[from] >= amount, "balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}

contract MockComposerOFT is IOFT {
    address public immutable override token;
    address public immutable endpoint;
    bool public immutable override approvalRequired;
    bool public failSend;
    bool public failSendWithoutReason;
    uint256 public nativeFee = 0.001 ether;

    constructor(address token_, address endpoint_, bool approvalRequired_) {
        token = token_; endpoint = endpoint_; approvalRequired = approvalRequired_;
    }
    function setFailSend(bool value) external { failSend = value; }
    function setFailSendWithoutReason(bool value) external { failSendWithoutReason = value; }
    function oftVersion() external pure override returns (bytes4, uint64) { return (0x02e49c2c, 1); }
    function sharedDecimals() external pure override returns (uint8) { return 6; }
    function quoteOFT(SendParam calldata p) external pure override returns (OFTLimit memory limit, OFTFeeDetail[] memory details, OFTReceipt memory receipt) {
        uint256 sent = p.amountLD - (p.amountLD % 10);
        limit = OFTLimit(0, type(uint256).max);
        details = new OFTFeeDetail[](0);
        receipt = OFTReceipt(sent, sent);
    }
    function quoteSend(SendParam calldata, bool) external view override returns (MessagingFee memory) {
        return MessagingFee(nativeFee, 0);
    }
    function send(SendParam calldata p, MessagingFee calldata fee, address) external payable override returns (MessagingReceipt memory mr, OFTReceipt memory receipt) {
        if (failSendWithoutReason) assembly { revert(0, 0) }
        require(!failSend, "send failed");
        require(msg.value == fee.nativeFee && fee.nativeFee == nativeFee, "fee");
        uint256 sent = p.amountLD - (p.amountLD % 10);
        if (approvalRequired) require(IERC20(token).transferFrom(msg.sender, address(this), sent), "transfer");
        mr = MessagingReceipt(keccak256(abi.encode(p, block.number)), 1, fee);
        receipt = OFTReceipt(sent, sent);
    }
}

contract MockComposerEndpoint {
    function compose(address composer, address from, bytes32 guid, bytes calldata message) external payable {
        ILayerZeroComposer(composer).lzCompose{ value: msg.value }(from, guid, message, address(this), "");
    }
}
