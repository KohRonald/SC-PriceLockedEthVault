// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {PriceLockedEthVault} from "src/PriceLockedEthVault.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployPriceLockedEthVault is Script {
    function deployContract() internal returns (PriceLockedEthVault) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        PriceLockedEthVault priceLockedEthVault = new PriceLockedEthVault(
            ethUsdPriceFeed
        );
        vm.stopBroadcast();
        return priceLockedEthVault;
    }

    function run() external {
        deployContract();
    }
}
