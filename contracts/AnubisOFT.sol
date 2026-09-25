// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OFTAlt } from "@layerzerolabs/oft-alt-evm/contracts/OFTAlt.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Shared Anubis OFT implementation for the ERC-20-gas EndpointV2Alt.
/// @dev Uses LayerZero's official OFTAlt implementation. Message fees are paid
/// by transferring endpoint.nativeToken() from the caller to the Endpoint.
abstract contract AnubisOFT is OFTAlt {

    constructor(string memory name_, string memory symbol_, address endpoint_, address delegate_)
        OFTAlt(name_, symbol_, endpoint_, delegate_)
        Ownable(delegate_)
    {}
}
