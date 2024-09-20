//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 10 ether; 
    uint256 constant STARTING_VALUE = 100 ether;
    uint256 constant GAS_PRICE = 1;
    
    HelperConfig helperConfig = new HelperConfig();
    address priceFeed = helperConfig.activeNetworkConfig();

    //this runs first
    function setUp() external {
      DeployFundMe deployFundMe = new DeployFundMe();
      fundMe = deployFundMe.run();
      vm.deal(USER,STARTING_VALUE);  // Help with funding the USER
    }

    function testMininumDollarsIsFive() view public {
        console.log(fundMe.MINIMUM_USD());
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() view public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() view public {
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert(); // The next lione, should revert !
        // assert(This Tx fails/reverts)
        fundMe.fund();

    }

    function testFundUpdateDataStructure() public {
        // This only works on test env, in foundry
        vm.prank(USER); // This means the next Tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
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

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        // Act
        // uint256 gasStart = gasleft();  //build in function in sol
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd ) * tx.gasprice;


        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFunMeBalance = address(fundMe).balance;
        assertEq(endingFunMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;   // numbers to generate addresses
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i < numberOfFunders ; i++){
            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance
        );


    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;   // numbers to generate addresses
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i < numberOfFunders ; i++){
            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance
        );


    }
}