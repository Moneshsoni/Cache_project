pragma solidity 0.8.9;
import "./cache.sol";
contract WORM is Cache{
    bytes4 constant public WRITE_ENTRY_CACHED = 0xe4e4f2d3;

    function writeEntryCached() external{
        uint[] memory params = _readParams(2);
        writeEntry(params[0], params[1]);
    }

    function readEntry(uint key)public view returns(uint _value, address _writtenBy, uint _writtenAtBlock){
        return (_value,_writtenBy,_writtenAtBlock);
    }
}