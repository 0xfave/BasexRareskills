// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { ERC20 } from "@solady/tokens/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20() {
        _mint(msg.sender, 1_000_000_000_000_000_000_000_000_000);
    }

    function name() public pure override returns (string memory) {
        return "Token";
    }

    function symbol() public pure override returns (string memory) {
        return "TKN";
    }
}
