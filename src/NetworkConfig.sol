// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../mocks/mockV3Aggregator.sol";
import {VRFCoordinatorV2Mock} from '../mocks/mockVRFCoordinatorV2.sol';
import {LinkToken} from '../mocks/LinkToken.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {NetworkDetails} from "./NetworkDetails.sol";

contract NetworkConfig is Script {

    // Error Definitions
    error MockNotAvailable(string mock_name);
    error ProcessNotImplemented(string process_name);
    error ProcessNotDefined(string process_name);
    error NetworkConfig_TokenNamesLengthMismatch(uint256 chain_id);
    error NetworkConfig_PriceFeedLengthMismatch(uint256 chain_id);
    error TokenNotUsed(string token_name);
    error NetworkConfig_NetworkNotRegistered(uint256 chain_id);

    // Constants
    uint8 public constant DECIMALS = 8;

    // State Variables
    mapping (string => bool) processes_needed;
    mapping (string => bool) processes_available;
    mapping (string => bool) token_defined;
    mapping (uint256 => NetworkDetails) public Networks;
    mapping (uint256 => bool) private registered_networks;
    mapping (string => uint256) public token_price;

    string[] processes_defined = ['VRFCoordinator','LinkToken','PriceFeeds','Tokens'];
    string[] tokensUsed;
    
    bool mock_deployed = false;
    NetworkDetails public activeNetworkDetails;

    // Events

    event HelperConfig_CreatedMock(string indexed  mock_type, address mock);

    constructor(string[] memory mocks_requested) {

        for(uint16 indx=0;indx<processes_defined.length;indx++){
            processes_available[processes_defined[indx]] = true;
        }
        for(uint16 indx=0; indx < mocks_requested.length; indx++){
            if(!processes_available[mocks_requested[indx]]) {
                revert ProcessNotDefined(mocks_requested[indx]);
            }
            processes_needed[mocks_requested[indx]] = true;
        }
    
    }


    function setActiveNetwork() public {
        uint256 chain_id = block.chainid;
        activeNetworkDetails = Networks[chain_id];
        if (!registered_networks[chain_id]) {
            setup_development_chain();
            activeNetworkDetails = Networks[chain_id];
        }
        if (processes_needed['Tokens'] && (activeNetworkDetails.getTokenNames().length != activeNetworkDetails.getTokenCount())) {
            revert NetworkConfig_TokenNamesLengthMismatch(chain_id);
        }
        if (processes_needed['PriceFeeds'] &&(activeNetworkDetails.getTokenCount() != activeNetworkDetails.getPriceFeedCount())) {
            revert NetworkConfig_PriceFeedLengthMismatch(chain_id);
        }
        if (processes_needed['VRFCoordinator'] && (activeNetworkDetails.getvrfCoordinator() == address(0))) {
            revert MockNotAvailable('VRFCoordinator');
        }
    }

    function setNetworkToChainId(uint chain_id) public {
        if (!registered_networks[chain_id]) {
            revert NetworkConfig_NetworkNotRegistered(chain_id);
        }
        activeNetworkDetails = Networks[chain_id];
    }

    function getActiveNetworkChainId() public view returns (uint256) {
        return activeNetworkDetails.getChainId();
    }

    function setup_development_chain() internal returns (NetworkDetails) {
        uint chainid = block.chainid;
        createNetwork(chainid,vm.envUint("PRIVATE_KEY_DEVELOPMENT"),false);
        NetworkDetails development_network = new NetworkDetails(chainid, vm.envUint("PRIVATE_KEY_DEVELOPMENT"), false);
        (
            address[] memory tokens_created,
            address[] memory pricefeeds_created,
            address vrf_coordinator,
            address link_token
        ) =  create_mocks();


        for(uint256 indx=0; indx < tokensUsed.length; indx++){
            addToken(chainid,tokensUsed[indx],tokens_created[indx],token_price[tokensUsed[indx]]);
        }

        for(uint256 indx=0; indx < pricefeeds_created.length; indx++){
            addPriceFeed(chainid,tokensUsed[indx],pricefeeds_created[indx]);
        }
        /*
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        */
        addVrfCoordinator(
            chainid,
            0.1 ether, 
            60, 
            vrf_coordinator,
            0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            0,
            500_000
        );

        addLinkToken(chainid,link_token);


        return development_network;
    }

    function createNetwork(uint256 chain_id, uint256 private_key, bool verify) public {
        NetworkDetails network = new NetworkDetails(chain_id, private_key, verify);
        Networks[chain_id] = network;
        registered_networks[chain_id] = true;
    }

    function addToken(uint256 chain_id, string memory token_name, address token_address, uint256 mock_price) public {
        Networks[chain_id].addToken(token_name, token_address);
        if(!token_defined[token_name]){
            tokensUsed.push(token_name);
            token_price[token_name] = mock_price;
            token_defined[token_name] = true;
        }
    }
    function addPriceFeed(uint256 chain_id, string memory token_name, address price_feed) public {
        if(!token_defined[token_name]){
            revert TokenNotUsed(token_name);
        }
        Networks[chain_id].addPriceFeed(token_name, price_feed);
    }
    function addVrfCoordinator(
        uint256 chainid,
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    )  public 
    {
        Networks[chainid].setVRFCoordinatorConfig(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
    }
    function addLinkToken(uint256 chainid, address linktoken) public {
        Networks[chainid].setLinkToken(linktoken);
    }

    function create_mocks() internal 
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
        
        address[] memory price_feeds = new address[](tokensUsed.length);
        address[] memory token_addresses = new address[](tokensUsed.length);
        
        uint96 baseFee = 0.25 ether; //0.25 LINK
        uint96 gasPriceLink = 1e9; //1 Gwei LINK

        if (mock_deployed == false){
            vm.startBroadcast();

            if(processes_needed['VRFCoordinator']){
                vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
                emit HelperConfig_CreatedMock("VRF Coordinator",address(vrfCoordinatorMock));
            }
            if(processes_needed['LinkToken']){

                linkToken = new LinkToken();
                emit HelperConfig_CreatedMock("LinkToken",address(linkToken));
            }
            if(processes_needed['Tokens']){
                for(uint16 indx=0;indx<tokensUsed.length;indx++){
                    ERC20 token = new Token(tokensUsed[indx], tokensUsed[indx]);
                    token_addresses[indx] = address(token);
                    emit HelperConfig_CreatedMock("Tokens",address(token));
                }
            }
            if(processes_needed['PriceFeeds']){
                for(uint16 indx=0;indx<tokensUsed.length;indx++){
                    v3AggregatorMock = new MockV3Aggregator(DECIMALS, 
                        int256(token_price[tokensUsed[indx]]*10**DECIMALS)
                        );
                    price_feeds[indx] = address(v3AggregatorMock);
                    emit HelperConfig_CreatedMock("PriceFeed",address(v3AggregatorMock));
                }
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

    function getPriceFeed(string memory coin) public view returns (address) {
        if(!processes_needed['PriceFeed']){
            revert ProcessNotImplemented('PriceFeed');
        }
        return activeNetworkDetails.getPriceFeed(coin);
    }
    function getAllPriceFeeds() public view returns (address[] memory) {
        if(!processes_needed['PriceFeed']){
            revert ProcessNotImplemented('PriceFeed');
        }
        address[] memory priceFeeds = new address[](tokensUsed.length);
        for(uint16 indx=0;indx<tokensUsed.length;indx++){
            priceFeeds[indx] = activeNetworkDetails.getPriceFeed(tokensUsed[indx]);
        }
        return priceFeeds;
    }
    
    function getTokens() public view returns (string[] memory) {

        if(!processes_needed['Tokens']){
            revert ProcessNotImplemented('Tokens');
        }
        return tokensUsed;
    }
    function getTokenAddress(string memory coin) public view returns (address) {
        if(!processes_needed['Tokens']){
            revert ProcessNotImplemented('Tokens');
        }
        return activeNetworkDetails.getTokenAddress(coin);
    }
    function getAllTokenAddresses() public view returns (address[] memory) {
        if(!processes_needed['Tokens']){
            revert ProcessNotImplemented('Tokens');
        }
        string[] memory tokens = getTokens();
        address[] memory tokenAddresses = new address[](tokens.length);
        for(uint16 indx=0;indx<tokens.length;indx++){
            tokenAddresses[indx] = activeNetworkDetails.getTokenAddress(tokens[indx]);
        }
        return tokenAddresses;
    }
    function get_vrfcoordinator_config() public view returns (uint256,uint256,address,bytes32,uint64,uint32) {
        if(!processes_needed['VRFCoordinator']){
            revert ProcessNotImplemented('VRFCoordinator');
        }
        NetworkDetails.VRFCoordinatorConfig memory vrf = activeNetworkDetails.getvrfCoordinatorConfig();
        return (vrf.entranceFee, vrf.interval, vrf.vrfCoordinator, vrf.gasLane, vrf.subscriptionId, vrf.callbackGasLimit);
    }

    function get_linktoken() public view returns (address) {
        if(!processes_needed['LinkToken']){
            revert ProcessNotImplemented('LinkToken');
        }
        return activeNetworkDetails.LinkToken();
    }

    function isMock() public view returns (bool) {
        return mock_deployed;
    }

    function getPrivateKey() public view returns (uint256) {
        return activeNetworkDetails.getPrivateKey();
    }

}

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000000000000000000000);
    }
}

