// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DeployPriceLockedEthVault} from "script/DeployPriceLockedEthVault.s.sol";
import {PriceLockedEthVault} from "src/PriceLockedEthVault.sol";

contract PriceLockedEthVaultTest is Test {
    PriceLockedEthVault public priceLockedEthVault;

    address public USER = makeAddr("user");
    uint256 public constant STARTING_ETH_BALANCE = 2 ether;

    event VaultLocked();
    event VaultLockReleased();
    event DepositedIntoVault(uint256 indexed ethAmount);
    event WithdrawFromVault(uint256 indexed ethAmount);

    function setUp() external {
        DeployPriceLockedEthVault deployer = new DeployPriceLockedEthVault();
        (priceLockedEthVault) = deployer.deployContract();
        deal(USER, STARTING_ETH_BALANCE);
    }

    modifier userDepositAndLocksVault() {
        vm.prank(USER);
        priceLockedEthVault.depositEth{value: 0.1 ether}();
        _;
    }

    //Test Pattern: Arrange, Act, Assert

    ///////////////////////////
    //    Initialize Tests   //
    ///////////////////////////
    function testVaultInitalizesInUnlockedState() public view {
        assert(
            priceLockedEthVault.getVaultState() ==
                PriceLockedEthVault.VaultState.UNLOCKED
        );
    }

    function testVaultInitalizesWithZeroBalance() public view {
        assert(priceLockedEthVault.getVaultBalance() == 0);
    }

    ////////////////////////////
    //      Deposit Tests     //
    ////////////////////////////
    function testUserDepositsSufficientEth() public {
        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(priceLockedEthVault));

        emit DepositedIntoVault(0.1 ether);
        emit VaultLocked();
        priceLockedEthVault.depositEth{value: 0.1 ether}();
    }

    function testUserDepositsInsufficientEth() public {
        vm.prank(USER);

        vm.expectRevert(
            PriceLockedEthVault
                .PriceLockedEthVault__EthDepositedIsNotSufficient
                .selector
        );
        priceLockedEthVault.depositEth{value: 0.05 ether}();
    }

    function testSuccessfulDepositLocksVault() public {
        vm.prank(USER);

        priceLockedEthVault.depositEth{value: 0.1 ether}();

        assert(
            priceLockedEthVault.getVaultState() ==
                PriceLockedEthVault.VaultState.LOCKED
        );
    }

    function testSuccessfulDepositintoLockedVault() public {
        vm.prank(USER);
        priceLockedEthVault.depositEth{value: 0.1 ether}();

        vm.expectEmit(true, false, false, false, address(priceLockedEthVault));
        emit DepositedIntoVault(0.1 ether);

        vm.prank(USER);
        priceLockedEthVault.depositEth{value: 0.1 ether}();
    }

    function testNonVaultUserDepositIntoLockedVault() public {
        address user2 = address(uint160(0));

        vm.prank(USER);
        priceLockedEthVault.depositEth{value: 0.1 ether}();

        hoax(user2, STARTING_ETH_BALANCE);
        vm.expectRevert(
            PriceLockedEthVault
                .PriceLockedEthVault__VaultIsCurrentlyBeingInUsedByAnotherUser
                .selector
        );
        priceLockedEthVault.depositEth{value: 0.1 ether}();
    }

    /////////////////////////////
    //      Withdraw Tests     //
    /////////////////////////////

    function testVaultHasNotHitMinimumUsdForWithdrawl()
        public
        userDepositAndLocksVault
    {
        vm.prank(USER);
        vm.expectRevert(
            PriceLockedEthVault
                .PriceLockedEthVault__VaultHasNotHitMinimumUsdValueForWithdrawal
                .selector
        );
        priceLockedEthVault.withdrawEth();
    }

    function testSuccessfulVaultWithdrawl() public userDepositAndLocksVault {
        vm.startPrank(USER);
        priceLockedEthVault.depositEth{value: 1 ether}();

        vm.expectEmit(true, false, false, false, address(priceLockedEthVault));
        emit WithdrawFromVault(1.1 ether);

        priceLockedEthVault.withdrawEth();

        vm.stopPrank();
    }

    function testUserReceiveEthFromSuccessfulVaultWithdrawl()
        public
        userDepositAndLocksVault
    {
        vm.startPrank(USER);
        priceLockedEthVault.depositEth{value: 1 ether}();
        priceLockedEthVault.withdrawEth();
        vm.stopPrank();

        assert(USER.balance == 2 ether);
    }

    function testSuccessfulVaultLockRelease() public userDepositAndLocksVault {
        vm.startPrank(USER);
        priceLockedEthVault.depositEth{value: 1 ether}();

        vm.expectEmit(true, false, false, false, address(priceLockedEthVault));
        emit VaultLockReleased();

        priceLockedEthVault.withdrawEth();

        vm.stopPrank();
    }

    function testVaultCannotBeCalledByNonOwner()
        public
        userDepositAndLocksVault
    {
        address user2 = address(uint160(0));

        vm.expectRevert(
            PriceLockedEthVault
                .PriceLockedEthVault__OnlyVaultUserCanUtiliseTheVault
                .selector
        );

        vm.prank(user2);
        priceLockedEthVault.withdrawEth();
    }
}
