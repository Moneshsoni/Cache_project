// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Cache{
    bytes1 public constant INTO_CACHE = 0xFF;
    bytes1 public constant DONT_CACHE = 0xFE;

    mapping(uint => uint)public val2key;
    uint[] public key2val;



    function cacheRead(uint _key)public view returns(uint){
        require(_key <= key2val.length,"Reading uninitialized cache entry");
        return key2val[_key-1];
    }

    // Write a value to the cache if it's not there already
    // Only public to enable the test to work

    function cacheWrite(uint _value)public returns(uint){
        //If the value iis already in the cache return the current key
        if(val2key[_value]!=0){
            return val2key[_value];
        }
        require(key2val.length+1 < 0x0DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
            "cache overflow");
    }
}