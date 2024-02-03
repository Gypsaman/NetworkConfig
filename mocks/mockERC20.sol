//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract mockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 ether);
        
    }
    
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}