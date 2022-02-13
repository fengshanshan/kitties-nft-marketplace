// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;
    
    modifier OnlyOwner {
        require(msg.sender == owner);
        _; // run the fnuction
    }
    
    constructor () {
        owner = msg.sender;
    }
}