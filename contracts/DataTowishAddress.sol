// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.20 <0.9.0;

contract DataToZeroAddress {
    struct MethodCall {
        address caller;
        string methodName;
        bytes data;
        uint256 timestamp;
    }
    
    MethodCall[] public methodCalls;
    
    event DataStored(address indexed sender, string methodName, bytes data, uint256 callIndex, uint256 timestamp);

    function storeData(bytes memory _data) public {
        methodCalls.push(MethodCall({
            caller: msg.sender,
            methodName: "storeData",
            data: _data
        }));
        
        emit DataStored(msg.sender, "storeData", _data, methodCalls.length - 1, block.timestamp);
    }
    
    function getMethodCall(uint256 _index) public view returns (address caller, string memory methodName, bytes memory data, uint256 timestamp) {
        require(_index < methodCalls.length, "Index out of bounds");
        MethodCall memory call = methodCalls[_index];
        return (call.caller, call.methodName, call.data, call.timestamp);
    }
    
    function getAllMethodCalls() public view returns (MethodCall[] memory) {
        return methodCalls;
    }
}
