// SPDX-License-Identiifier: MIT
pragma solidity ^0.8.11;

contract multiSigWallet{
    event deposit (address indexed sender, uint256 amount);
    event submit (uint256 txId);
    event Approve( address indexed owner, uint256 txId);
    event Revoke( address indexed owner, uint256 indexed txId );
    event execute( uint256 indexed txId);

    address[] public owners;
    mapping(address=> bool) public isOwner;
    uint256 public required;
    struct Transaction{
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }
    Transaction[] public transactions;
    mapping(uint256 =>uint256) public transactionExists;
    mapping(uint256 => mapping(address=> bool )) public approved;

    constructor(address[] memory _owners, uint256 _required){
        require(_owners.length >0, "owner required");
        require(required > 0 && required<_owners.length, "invalid required number of owners" );

        for (uint i; i<_owners.length; i ++){
            address owner = _owners[i];
            require(!isOwner[owner], "is already owner");
            require(owner != address(0), "address 0 owner is invalid");

            owners.push(owner);
            isOwner[owner = true];

        }
        
        required = _required;
    }
    receive() external payable{
        emit deposit(msg.sender, msg.value);
    }
    modifier onlyOwner{
        require(isOwner[msg.sender], "is not the owner");
        _;
    }
    function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner{
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        unit256 txId = (transactions.length - 1);
        transactions[txId] = true;
        emit submit(txId);
    }
    modifier txIdExists(uint _tx){
        require(transactionExists[_tx],"transaction does not exist");
        _;
    }
    modifier notApprovedTxId(uint _tx){
        require(!approved[_tx][msg.sender], "transaction Approved");
    }
    modifier notExecuted(uint _tx){
        require(!transactions[_tx].executed, "transaction already executed");
        _;
    }
    function Approve(uint256 _txId) external onlyOwner txIdExists(_txId) notApprovedTxId(_txId) notExecuted(_txId){
        appoved[_txId][msg.sender] = true;
        emit Approve(msg.sender, txId);
    }
    function getApprovalCount(uint256 _txId) private view returns(uint256 count){
        for (uint i; i<owners.length; i ++){
            if(approved[_txId][owners[i]]){
                count +=1;
            }
        }
    }
    function execute(uint256 _txId) external txIdExists(_txId) notExecuted(_txId) {
        require(getApprovalCount<required, " not reached approval count");
        Transaction storage txn = transactions[_txId];
        txn.executed = true;
        (bool success, ) = txn.to.call{value:txn.value}(txn.data);
        require(success, "execution failed");
        emit execute(_txId);
    }
    function Revoke(uint256 _txId) external onlyOwner txIdExists(_txId) notExecuted(_txId){
        require(Approved[_txId][msg.sender], "transaction not approved");
        Approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, txId);
    }
}