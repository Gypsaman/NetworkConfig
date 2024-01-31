// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../mocks/mockV3Aggregator.sol";
import {VRFCoordinatorV2Mock} from '../mocks/mockVRFCoordinatorV2.sol';
import {LinkToken} from '../mocks/LinkToken.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {NetworkConfig} from "./NetworkConfig.sol";

contract HelperConfig is Script {

    error MockNotAvailable();
    error NetworkConfig_TokenNamesLengthMismatch(uint256 chain_id);

    uint8 public constant DECIMALS = 8;

    mapping (string => bool) mocks_needed;
    mapping (string => bool) mocks_available;
    string[] mocks_defined = ['VRFCoordinator','LinkToken','PriceFeed','Tokens'];
    string[] token_names = ['WETH','WBTC'];
    uint256[] token_prices = [2000, 40000];

    bool mock_deployed = false;
    NetworkConfig mocks;
    



    event HelperConfig_CreatedMock(string indexed  mock_type, address mock);

    mapping (uint256 => NetworkConfig) public Networks;

    NetworkConfig public activeNetworkConfig;

    constructor(string[] memory mocks_requested) {

        for(uint16 indx=0;indx<mocks_defined.length;indx++){
            mocks_available[mocks_defined[indx]] = true;
        }
        
        for(uint16 indx=0; indx < mocks_requested.length; indx++){
            if(!mocks_available[mocks_requested[indx]]) {
                revert MockNotAvailable();
            }
            mocks_needed[mocks_requested[indx]] = true;
        }

        setup_chains();
        activeNetworkConfig = Networks[block.chainid];
        if (activeNetworkConfig.getPrivateKey() == 0) {
            setup_development_chain();
        }
    }

    function setup_development_chain() internal {
        (address[] memory tokens, address[] memory price_feeds, address vrf_coordinator, address link_token) = get_mocks();
        activeNetworkConfig = new NetworkConfig(block.chainid, vm.envUint("PRIVATE_KEY_DEVELOPMENT"), false);

        activeNetworkConfig.setVRFCoordinatorConfig(
            0.1 ether, 
            60, 
            vrf_coordinator,
            0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            0,
            500_000
        );

        activeNetworkConfig.setLinkToken(link_token);
        activeNetworkConfig.setTokens(tokens,token_names);
        activeNetworkConfig.setPriceFeeds(price_feeds);
    }
    function setup_chains() public {
        setup_sepolia();
        
    }
    
    function setup_sepolia() public {
        uint256 chain_id = 11155111;
        address[] memory priceFeeds = new address[](token_names.length);
        address[] memory tokens = new address[](token_names.length);
        
        priceFeeds[0] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[1] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        tokens[0] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        tokens[1] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        
        if(priceFeeds.length != token_names.length) {
            revert NetworkConfig_TokenNamesLengthMismatch(chain_id);
        }
        NetworkConfig network = new NetworkConfig(chain_id, vm.envUint("PRIVATE_KEY"), false);
        NetworkConfig.VRFCoordinatorConfig memory vrf = NetworkConfig.VRFCoordinatorConfig(
                {entranceFee: 0.1 ether,
                interval: 60,
                vrfCoordinator:0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane:0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit:500_000
                });
        network.setVRFCoordinatorConfig(vrf.entranceFee, vrf.interval, vrf.vrfCoordinator, vrf.gasLane, vrf.subscriptionId, vrf.callbackGasLimit);
        network.setLinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        network.setTokens(tokens,token_names);
        network.setPriceFeeds(priceFeeds);
        Networks[chain_id] = network;
    }


    function get_mocks() public 
        returns (
            address[] memory, 
            address[] memory,
            address,
            address
        )
        {

        MockV3Aggregator v3AggregatorMock;
        VRFCoordinatorV2Mock vrfCoordinatorMock;
        LinkToken linkToken;
        address[] memory token_addresses = new address[](token_names.length);
        
        address[] memory price_feeds = new address[](token_names.length);
        
        uint96 baseFee = 0.25 ether; //0.25 LINK
        uint96 gasPriceLink = 1e9; //1 Gwei LINK

        if (mock_deployed == false){
            vm.startBroadcast();

            if(mocks_needed['VRFCoordinator']){
                vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
                emit HelperConfig_CreatedMock("VRF Coordinator",address(vrfCoordinatorMock));
            }
            if(mocks_needed['LinkToken']){

                linkToken = new LinkToken();
                emit HelperConfig_CreatedMock("LinkToken",address(vrfCoordinatorMock));
            }
            if(mocks_needed['Tokens']){
                for(uint16 indx=0;indx<token_names.length;indx++){
                    ERC20 token = new Token(token_names[indx], token_names[indx]);
                    token_addresses[indx] = (address(token));
                    emit HelperConfig_CreatedMock("Tokens",address(vrfCoordinatorMock));
                }
                activeNetworkConfig.setTokens(token_addresses,token_names);
            }
            if(mocks_needed['PriceFeed']){
                for(uint16 indx=0;indx<token_names.length;indx++){
                    v3AggregatorMock = new MockV3Aggregator(DECIMALS, int256(token_prices[indx]*10**DECIMALS));
                    price_feeds[indx] = (address(v3AggregatorMock));
                    emit HelperConfig_CreatedMock("PriceFeed",address(v3AggregatorMock));
                }
                activeNetworkConfig.setPriceFeeds(price_feeds);
            }
            vm.stopBroadcast();
            mock_deployed = true;
            
        }

        return (
            token_addresses,
            price_feeds, 
            address(vrfCoordinatorMock), 
            address(linkToken)
        );
    }

    function get_pricefeed(string memory coin) public view returns (address) {
        if(!mocks_needed['PriceFeed']){
            revert MockNotAvailable();
        }
        return activeNetworkConfig.getPriceFeed(coin);
    }
    function get_tokenAddress(string memory coin) public view returns (address) {
        if(!mocks_needed['Tokens']){
            revert MockNotAvailable();
        }
        return activeNetworkConfig.getTokenAddress(coin);
    }
    function get_vrfcoordinator_config() public view returns (uint256,uint256,address,bytes32,uint64,uint32) {
        if(!mocks_needed['VRFCoordinator']){
            revert MockNotAvailable();
        }
        NetworkConfig.VRFCoordinatorConfig memory vrf = activeNetworkConfig.getvrfCoordinatorConfig();
        return (vrf.entranceFee, vrf.interval, vrf.vrfCoordinator, vrf.gasLane, vrf.subscriptionId, vrf.callbackGasLimit);
    }

    function get_linktoken() public view returns (address) {
        if(!mocks_needed['LinkToken']){
            revert MockNotAvailable();
        }
        return activeNetworkConfig.LinkToken();
    }

    function isMock() public view returns (bool) {
        return mock_deployed;
    }

    function getPrivateKey() public view returns (uint256) {
        return activeNetworkConfig.getPrivateKey();
    }

}

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000000000000000000000);
    }
}

