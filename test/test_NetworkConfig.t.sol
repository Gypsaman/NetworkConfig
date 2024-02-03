// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DeployNetworkConfig} from '../script/DeployNetworkConfig.s.sol';
import {NetworkConfig} from '../src/NetworkConfig.sol';

contract Test_NetworkConfig is Test {
    NetworkConfig network;
    DeployNetworkConfig deployer;
    function setUp() public {
         deployer = new DeployNetworkConfig();
         network = deployer.run();
        deployer.setup_sepolia();
    }
    
    function test_sepolia() public {
        network.setNetworkToChainId(11155111);
        assertEq(11155111,network.getActiveNetworkChainId());
    }

    function test_getPrivateKey() public {
        network.setNetworkToChainId(11155111);
        assertEq(vm.envUint("PRIVATE_KEY"),network.getPrivateKey());
    }
    function test_getAllPriceFeeds() public {
        network.setNetworkToChainId(11155111);
        uint256 token_count = network.getTokens().length;
        address[] memory feeds = new address[](token_count);
        feeds = network.getAllPriceFeeds();
        assertEq(token_count,feeds.length);
        
    }
}
