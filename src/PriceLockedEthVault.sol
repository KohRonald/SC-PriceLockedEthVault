// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PriceConvertor} from "src/PriceConvertor.sol";
import {AggregatorV3Interface} from "@chainlink/shared/interfaces/AggregatorV3Interface.sol";

/// @title PriceLockedEthVault Contract
/// @author Ronald Koh
/// @notice Single user locked contract mechanism, Locks their deposited ETH into a vault, Only allow Withdrawl if total value of vault hits a certain price
/// @dev Implements Chainlink VRFv2.5

contract PriceLockedEthVault {
    using PriceConvertor for uint256;

    /* Errors */
    error PriceLockedEthVault__EthDepositedIsNotSufficient();
    error PriceLockedEthVault__OnlyVaultUserCanUtiliseTheVault();
    error PriceLockedEthVault__VaultIsCurrentlyBeingInUsedByAnotherUser();
    error PriceLockedEthVault__VaultHasNoEther();
    error PriceLockedEthVault__VaultHasNotHitMinimumUsdValueForWithdrawal();

    /* Type Declarations */
    enum VaultState {
        UNLOCKED,
        LOCKED
    }

    /* State Variables */
    uint256 private constant MINIMUM_ETH = 0.1 ether;
    uint256 private constant MINIMUM_VAULT_USD_WITHDRAWL_VALUE = 1000 * 1e18; //Scale with 18 decimals
    address private s_vaultUser;
    VaultState private s_locked;
    AggregatorV3Interface private s_priceFeed;

    /* Events */
    event VaultLocked();
    event VaultLockReleased();
    event DepositedIntoVault(uint256 indexed ethAmount);
    event WithdrawFromVault(uint256 indexed ethAmount);

    constructor(address priceFeedAddress) {
        s_locked = VaultState.UNLOCKED;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyCurrentVaultUser() {
        if (address(msg.sender) != s_vaultUser) {
            revert PriceLockedEthVault__OnlyVaultUserCanUtiliseTheVault();
        }
        _;
    }

    //Function Pattern: Checks, Effects, Interactions

    function depositEth() external payable {
        if (msg.value < MINIMUM_ETH) {
            revert PriceLockedEthVault__EthDepositedIsNotSufficient();
        }
        if (
            s_locked == VaultState.LOCKED && s_vaultUser != address(msg.sender)
        ) {
            revert PriceLockedEthVault__VaultIsCurrentlyBeingInUsedByAnotherUser();
        }

        if (s_locked != VaultState.LOCKED) {
            s_vaultUser = msg.sender;
            s_locked = VaultState.LOCKED;
            emit VaultLocked();
            emit DepositedIntoVault(msg.value);
        } else {
            emit DepositedIntoVault(msg.value);
        }
    }

    function withdrawEth() external payable onlyCurrentVaultUser {
        //Checks
        uint256 vaultBalance = address(this).balance;
        if (vaultBalance == 0 ether) {
            revert PriceLockedEthVault__VaultHasNoEther();
        }

        if (
            vaultBalance.calculateTotalBalanceInUsd(s_priceFeed) <
            MINIMUM_VAULT_USD_WITHDRAWL_VALUE
        ) {
            revert PriceLockedEthVault__VaultHasNotHitMinimumUsdValueForWithdrawal();
        }

        //Effects
        s_locked = VaultState.UNLOCKED;
        s_vaultUser = address(0);

        //Interactions
        emit WithdrawFromVault(vaultBalance);
        emit VaultLockReleased();

        payable(msg.sender).transfer(vaultBalance);
    }

    /* Getters */
    function getVaultState() external view returns (VaultState) {
        return s_locked;
    }

    function getVaultUser() external view returns (address) {
        return s_vaultUser;
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getCurrentTotalVaultValue() external view returns (uint256) {
        return (address(this).balance).calculateTotalBalanceInUsd(s_priceFeed); //return amount will have 18 trailing decimals
    }

    function getPriceFeedVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getMinimumVaultUsdWithdrawlValue() public pure returns (uint256) {
        return MINIMUM_VAULT_USD_WITHDRAWL_VALUE;
    }
}
