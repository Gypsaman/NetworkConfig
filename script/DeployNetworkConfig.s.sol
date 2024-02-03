// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from 'forge-std/Script.sol';
import {NetworkConfig} from '../src/NetworkConfig.sol';


contract DeployNetworkConfig is Script {

    string[] functions_needed = ['VRFCoordinator','LinkToken','PriceFeeds','Tokens'];
    NetworkConfig network;

    function run() external returns (NetworkConfig) {

        network = new NetworkConfig(functions_needed);

        return network;
    }
    function setup_sepolia() public {

        uint256 chainid = 11155111;
        network.createNetwork(chainid,vm.envUint("PRIVATE_KEY"),false);
        network.addToken(chainid,'WETH',0xdd13E55209Fd76AfE204dBda4007C227904f0a81);
        network.addToken(chainid,'WBTC',0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        network.addPriceFeed(chainid,'WETH',0x694AA1769357215DE4FAC081bf1f309aDC325306);
        network.addPriceFeed(chainid,'WBTC',0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        network.addVrfCoordinator(chainid,0.1 ether,60,0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,0,500_000);
        network.addLinkToken(chainid,0x779877A7B0D9E8603169DdbD7836e478b4624789);

    }
}