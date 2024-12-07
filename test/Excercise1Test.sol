// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";
import { ERC20 } from "../src/ERC20.sol";

contract ERC20Test is Test {
    ERC20 public token;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user2 = makeAddr("user3");
        token = new ERC20("Test Token", "TEST", 18, 1_000_000e18);
        // Transfer initial tokens to user1
        token.transfer(user1, 10_000e18);
    }

    function testInitialState() public {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 1_000_000e18);
        assertEq(token.balanceOf(owner), 990_000e18);
    }

    function testTransfer() public {
        uint256 amount = 1000e18;
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user3, amount);

        bool success = token.transfer(user3, amount);
        assertTrue(success);
        assertEq(token.balanceOf(user3), amount);
        assertEq(token.balanceOf(owner), 990_000e18 - amount);
    }

    function testTransferFailsInsufficientBalance() public {
        uint256 amount = 1_000_001e18; // More than total supply
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transfer(user1, amount);
    }

    function testApprove() public {
        uint256 amount = 1000e18;
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, user1, amount);

        bool success = token.approve(user1, amount);
        assertTrue(success);
        assertEq(token.allowance(owner, user1), amount);
    }

    function testTransferFrom() public {
        uint256 amount = 1000e18;
        token.approve(user1, amount);

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user2, amount);

        bool success = token.transferFrom(owner, user2, amount);
        assertTrue(success);
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.allowance(owner, user1), 0);
    }

    function testTransferFromFailsInsufficientAllowance() public {
        uint256 amount = 1000e18;
        token.approve(user1, amount - 1);

        vm.prank(user1);
        vm.expectRevert("ERC20: insufficient allowance");
        token.transferFrom(owner, user2, amount);
    }

    function testTransferFromFailsInsufficientBalance() public {
        uint256 amount = 1_000_001e18; // More than total supply
        token.approve(user1, amount);

        vm.prank(user1);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transferFrom(owner, user2, amount);
    }

    function testAllowanceAfterTransferFrom() public {
        uint256 approveAmount = 1000e18;
        uint256 transferAmount = 500e18;

        token.approve(user1, approveAmount);
        vm.prank(user1);
        token.transferFrom(owner, user2, transferAmount);

        assertEq(token.allowance(owner, user1), approveAmount - transferAmount);
    }

    function testZeroTransfer() public {
        bool success = token.transfer(user3, 0);
        assertTrue(success);
        assertEq(token.balanceOf(user3), 0);
    }

    function testZeroApprove() public {
        bool success = token.approve(user1, 0);
        assertTrue(success);
        assertEq(token.allowance(owner, user1), 0);
    }
}
