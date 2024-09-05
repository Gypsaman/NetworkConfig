// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console} from 'forge-std/console.sol';

contract NetworkDetails {


    error NetworkDetails_TokenNamesLengthMismatch();  
    struct VRFCoordinatorConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    mapping(string => address) coinToPriceFeeds;
    mapping(string => address) coinToTokens;

    uint256 public chain_id;
    uint256 private private_key;
    address[] public priceFeeds;
    address[] public tokens;
    string [] public tokenNames;
    bool public verify;
    VRFCoordinatorConfig public vrfCoordinatorConfig;

    /* 
    * address LinkToken is seperate of tokens because of it's ERC223 implementation of TransferAndCall
    * will look to see how to merge with regular tokens in the future (if possible)
    */

    address public LinkToken;

    constructor(uint256 _chain_id, uint256 _private_key, bool _verify) {
        chain_id = _chain_id;
        private_key = _private_key;
        verify = _verify;
    }

    function _addToken(string memory tokenName, address tokenAddress) public {
        tokenNames.push(tokenName);
        tokens.push(tokenAddress);
        coinToTokens[tokenName] = tokenAddress;
    }
    function _addPriceFeed(string memory tokenName, address priceFeed) public {
        priceFeeds.push(priceFeed);
        coinToPriceFeeds[tokenName] = priceFeed;
    }
    function setVRFCoordinatorConfig(uint256 _entranceFee, uint256 _interval, address _vrfCoordinator, bytes32 _gasLane, uint64 _subscriptionId, uint32 _callbackGasLimit) public {
        vrfCoordinatorConfig = VRFCoordinatorConfig(_entranceFee, _interval, _vrfCoordinator, _gasLane, _subscriptionId, _callbackGasLimit);
    }
    function setLinkToken(address _LinkToken) public {
        LinkToken = _LinkToken;
    }
    function getpriceFeed(string memory coin) public view returns (address) {
        return coinToPriceFeeds[coin];
    }
    function _getTokenAddress(string memory coin) public view returns (address) {
        return coinToTokens[coin];
    }
    function _getPriceFeed(string memory coin) public view returns (address) {
        return coinToPriceFeeds[coin];
    }
    function _getPrivateKey() public view returns (uint256) {
        return private_key;
    }
    function getvrfCoordinatorConfig() public view returns (VRFCoordinatorConfig memory) {
        return vrfCoordinatorConfig;
    }

    function getvrfCoordinator() public view returns (address) {
        return vrfCoordinatorConfig.vrfCoordinator;
    }
    
    function getPriceFeedCount() public view returns (uint256) {
        return priceFeeds.length;
    }

    function getTokenCount() public view returns (uint256){
        return tokens.length;
    }

    function getTokenNames() public view returns (string[] memory) {
        return tokenNames;
    }

    function getChainId() public view returns (uint256) {
        return chain_id;
    }
}