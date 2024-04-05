// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

//import {FundMe__NotOwner} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant START_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //us calling FundMeTest which deploys FundMe
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, START_BALANCE);
    }

    function testMinimumDollarIsFive() external view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() external view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    /*function testWithdrawNotOwner() external {
        vm.prank(address(1));
        // Declare the FundMe__NotOwner variable or function here
        // Example: uint256 FundMe__NotOwner;
        // or: function FundMe__NotOwner() external {}
        vm.expectRevert(FundMe__NotOwner.selector);
        fundMe.withdraw();
    }*/

    /*function testOwnerIsSetCorrectly() external view {
        assertEq(fundMe.i_owner(), address(this));  second test i wrote myself
    }*/
    function testPriceFeedVersionIsAccurate() external view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughEth() external {
        vm.expectRevert(); //next line should revert
        fundMe.fund();
    }

    function testFundUpdateFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayofFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnwerCanWithdraw() public funded {
        vm.prank(USER);

        vm.expectRevert(); //next line should revert
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // how i write my test: arrange, act, assert

        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //AcT
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundMe
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundMe
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
