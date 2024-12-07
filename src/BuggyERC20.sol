// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The following ERC-20 token’s freeze function can be bypassed. Write a unit test showing how to do this.
// In addition to being able to bypass the freeze, it also has an extremely serious vulnerability. What is it?

contract StableCoin is ERC20Burnable, Ownable(msg.sender) {

    constructor() ERC20("MyBurnableToken", "MBT") {
        
    }
    
    mapping(address account => bool) public isFrozen;

    function mint(address receiver, uint256 amount) public onlyOwner { //> only owner can mint so the user can't mint another one for themselves
        _mint(receiver, amount);
    }

    function burn(address from, uint256 amount) public { //> @audit anyone can burn someone else's token
        _burn(from, amount);
    }

    function freeze(address account) public onlyOwner { //> freezes the user account
        isFrozen[account] = true;
    }

    function unfreeze(address account) public onlyOwner {
        isFrozen[account] = false;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(!isFrozen[msg.sender], "account frozen"); //> checks if the address is not frozen
        return super.transfer(to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) { //> if a user is frozen, he can approve someone else to spend their tokens it will work as long as the spender is not frozen
        require(!isFrozen[msg.sender], "account frozen"); //> checks if the address is not also frozen
        return super.transferFrom(from, to, amount);
    }
}
