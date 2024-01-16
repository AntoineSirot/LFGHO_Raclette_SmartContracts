// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {GHOStakingVault} from "../src/VaultContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Import the IERC20 interface

contract DeploymentScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ERC20 ghoTokenAddress = ERC20(
            0xc4bF5CbDaBE595361438F8c6a187bDc330539c60
        );
        string memory vaultTokenName = "Vault-Gho";
        string memory vaultTokenSymbol = "F-GHO";

        new GHOStakingVault(ghoTokenAddress, vaultTokenName, vaultTokenSymbol);

        vm.stopBroadcast();
    }
}
