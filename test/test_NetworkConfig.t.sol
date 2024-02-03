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
    }
    
    function test_sepolia() public {
        deployer.setup_sepolia();
        network.setNetworkToChainId(11155111);
        assertEq(11155111,network.getActiveNetworkChainId());
    }
}
