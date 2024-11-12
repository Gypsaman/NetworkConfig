# Network Config

Provides a mechanism to supply configurations of different Live networks, including testnets.  It also creates needed mocks for the development network(s).

## Dependencies:

`smartcontractkit/chainlink` @ https://github.com/smartcontractkit/chainlink/commit/2e8e16820b02a9ca83aa46e7ae2deac31eaf08aa

`

## Configurations Provided
- Tokens
- PriceFeeds (Aggregators)
- LinkToken
- VrfCoordinator


## Usage
In this example we utilize all four processes, if the process is not needed you can omit.
```
string[] processes_needed = ['VRFCoordinator','LinkToken','PriceFeeds','Tokens'];

NetworkConfig config = new NetworkConfig(processes_needed);


/*
* @param: uint256 chainid
* @param: uint256 privateKey: wallet to be utilized
* @param: bool verify:  To indicate if the network will verify the contract.  Currently not implemented.
*/
config.createNetwork(chainid,vm.envUint("PRIVATE_KEY"),false);
```

## Tokens
Process Name: 'Tokens'
Usage:
```
string[] processes_needed = ['Tokens',...];
NetworkConfig config = new NetworkConfig(processes_needed);

/*
* @param: uint256 chainid
* @param: string tokenSymbol: Symbol of token to add
* @param: address tokeAddress: address of token contract
* @param: uint256 mock_price: price of token in USD for mocks
*/
config.addToken(chainid,'WETH',0xdd13E55209Fd76AfE204dBda4007C227904f0a81,2000);
config.addToken(chainid,'WBTC',0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,40000);
# ...  Add as many tokens as needed
```

## PriceFeeds
Process Name: 'PriceFeeds'
Usage:
```
string[] processes_needed = ['PriceFeeds',...];
NetworkConfig config = new NetworkConfig(processes_needed);

/*
* @param: uint256 chainid
* @param: string tokenSymbol: Symbol of token to add
* @param: address tokeAddress: address of price feed contract
*/
config.addPriceFeed(chainid,'WETH',0x694AA1769357215DE4FAC081bf1f309aDC325306);
config.addPriceFeed(chainid,'WBTC',0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        
# ... Add as many priceFeeds as Tokens added.
```

## VRFCoordinator
Process Name: 'VRFCoordinator'
Usage:
```
string[] processes_needed = ['VRFCoordinator',...];
NetworkConfig config = new NetworkConfig(processes_needed);

/*
* @param: uint256 chainid  
* @param: uint256 entranceFee
* @param: uint256 interval -> number of seconds to call function
* @param: address vrfCoordinator -> address in current chain
* @param: bytes32 gasLane -> specifies cost/speed of vrfcoordinator
* @param: uint64 subscriptionId -> subscription setup in chainlink
* @param: uint32 callbackGasLimit -> limit of gas spent on call back function
*/

config.addVrfCoordinator(chainid,0.1 ether,60,0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,0,500_000);

```

## LinkToken
Process Name: 'LinkToken'
Usage:
```
string[] processes_needed = ['LinkToken',...];
NetworkConfig config = new NetworkConfig(processes_needed);
/*
* @param: uint256 chainid  
* @param: address LinkToken -> address of linktoken in chain
config.addLinkToken(chainid,0x779877A7B0D9E8603169DdbD7836e478b4624789);
```

## Active Network
This functions sets the active network to be utilized in the config.

```
/*
* @param: uint256 chainid
*/
config.setActiveNetwork(block.chainid);
```

# TODO
replace the lib/chainlink and lib/openzeppelin-contracts with their respective "@chainlink" "@OpenZeppelin"
