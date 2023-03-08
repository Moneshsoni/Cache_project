// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Cache{
    bytes1 public constant INTO_CACHE = 0xFF;
    bytes1 public constant DONT_CACHE = 0xFE;

    mapping(uint => uint)public val2key;
    uint[] public key2val;

    function cacheRead(uint _key)public view returns(uint){
        require(_key <=key2val.length,"Reading uninitialized cache entry");
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

        val2key[_value] = key2val.length+1;
        key2val.push(_value);
        return key2val.length;
    }

    function _calldataVal(uint startByte,uint length)private
    pure returns(uint){
        uint _retVal;
        require(length< 0x21,"_calldata length limit is 32 bytes");
        require(length + startByte<= msg.data.length,"_calldataVal trying to read beyond calldatasize");
        assembly {
            _retVal := calldataload(startByte)
        }

        _retVal = _retVal >> (256-length*8);
        return _retVal;
    }

    function _readParam(uint _fromByte)internal returns
    (uint _nextByte, uint _parameterValue){
        uint8 _fairstByte;

        _fairstByte = uint8(_calldataVal(_fromByte, 1));

        //Read the value and write it to the cache
        if(_fairstByte == uint8(INTO_CACHE)){
            uint _param = _calldataVal(_fromByte+1, 32);
            cacheWrite(_param);

            return(_fromByte+33,_param);
        }

        // If we got here it means that we need to read from the cache
        // Number of extra bytes to read
        uint8 _extraBytes = _fairstByte / 16;

        uint _key = (uint256(_fairstByte & 0x0F) << (8*_extraBytes))+
        _calldataVal(_fromByte+1, _extraBytes);

        return (_fromByte+_extraBytes+1, cacheRead(_key));

    }

    function _readParams(uint _paramNum)internal returns(uint[] memory){
        // The parameters we read

        uint[] memory params = new uint[](_paramNum);
        //parameters start at byte 4 before that it's the func
        //ction signatue

        uint _atByte = 4;

        for(uint i =0; i<_paramNum;i++){
            (_atByte, params[i]) = _readParam(_atByte);
        }

        return(params);
    }

    function fourParam() public returns(uint256,uint256,uint256,uint256){
        uint[] memory params;
        params = _readParams(4);
        return (params[0],params[1],params[2],params[3]);
    }

    function encodeVal(uint _val)public view returns(bytes memory){
        uint _key = val2key[_val];

        if(_key ==0){
            return bytes.concat(INTO_CACHE, bytes32(_val));
        }

        if (_key < 0x10)
            return bytes.concat(bytes1(uint8(_key)));

         // Two byte value, encoded as 0x1vvv
        if (_key < 0x1000)
            return bytes.concat(bytes2(uint16(_key) | 0x1000));

                // There is probably a clever way to do the following lines as a loop,
        // but it's a view function so I'm optimizing for programmer time and
        // simplicity.

        if (_key < 16*256**2)
            return bytes.concat(bytes3(uint24(_key) | (0x2 * 16 * 256**2)));
        if (_key < 16*256**3)
            return bytes.concat(bytes4(uint32(_key) | (0x3 * 16 * 256**3)));
     
        if (_key < 16*256**14)
            return bytes.concat(bytes15(uint120(_key) | (0xE * 16 * 256**14)));
        if (_key < 16*256**15)
            return bytes.concat(bytes16(uint128(_key) | (0xF * 16 * 256**15)));
        revert("Error in encodeVal, should not happen");
    }

    function bytesToUint(bytes memory b) public pure returns (uint256){
            uint256 number;
            for(uint i=0;i<b.length;i++){
                number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
            }
        return number;
    }

}