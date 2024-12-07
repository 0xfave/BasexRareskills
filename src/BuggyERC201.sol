// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// There are two ways that the withdraw function can fail, leading to tokens getting stuck in the contract. What are they? Write a foundry unit test that shows someone trying to recover the token they deposited and rightfully own, but cannot withdraw.

// Hint: for a transaction to fail, a require statement needs be violated, or a revert get triggered. Revisit the ERC-20 library for ideas.

contract NotBasedToken is ERC20Pausable, Ownable {
		constructor(address rewarder) ERC20("NBToken", "NBT") Ownable(msg.sender) {
			_mint(rewarder, 100_000_000e18);
		}
		
		function pause() external onlyOwner {
				_pause();
		}
		
		function unpause() external onlyOwner {
				_unpause();
		}
}

contract NotBasedRewarder {
		IERC20 rewardToken;
		IERC20 depositToken;
		
		constructor(IERC20 _rewardToken, IERC20 _depositToken) {
				rewardToken = _rewardToken;
				depositToken = _depositToken;
		}
		
		mapping(address => uint256) internalBalances;
		mapping(address => uint256) depositTime; 
		
		function deposit(uint256 amount) public {
				require(rewardToken.allowance(msg.sender, address(this)) > amount, "insufficient allowance"); //> @audit user won't be able to deposit because of the wrong token allowance chack
				
				depositToken.transferFrom(msg.sender, address(this), amount);
				internalBalances[msg.sender] += amount;
				depositTime[msg.sender] = block.timestamp;
		}
		
		// give a bonus if they staked for more than 24 hours
		function withdraw(uint256 amount) external { //> @audit this can fail because the tokens can be paused
				require(amount < internalBalances[msg.sender], "insufficient balance"); //> @audit user can not withdraw the exact amount the deposited
				if (block.timestamp > depositTime[msg.sender] + 24 hours) {
						rewardToken.transfer(msg.sender, amount);
				}
				
				// give back their tokens
				depositToken.transfer(msg.sender, amount);
		} //> @audit user can keep calling withdraw because the internal accounting is not updated after each withdraw
}
