pragma solidity ^0.4.0;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}



contract BTM is owned{
    mapping (address => int256) private balanceOf;//cg: represent balance of each account
   // mapping (address => string) public nameOf;//bank address - bank name
    mapping (string => address[]) atmsOf;//bank address - the atms[] of the bank
    //event Withdrawal(string _issueBank, string _account, string _pwd, int _amount);
    int constant STATUS_OK = 1000;
    //event to notify the specific debit bank ATM node to check whether the transaction can be debitted from the debit bank account.
    //the debit bank has the right to know all transaction information
    //pls note that this event reuqire _debitBankAtm address
    event CheckDebit(address _fromAtm, address _debitBankAtm, string _creditBank,  string _trxHash, int256 _amount, int256 _fee);
    
    //event to notify the specific credit bank ATM node to check whether the transaction can be creditted to the credit bank account.
    //the credit bank has the right to know all transaction information
    //pls note that this event reuqire _creditBankAtm address
    event CheckCredit(address _fromAtm, address _debitBankAtm, address _creditBankAtm,string _trxHash, int256 _amount, int256 _fee);//the debit bank has the right to know all transaction information
    //event to notify the _fromAtm node to commit the transaction
    event Commit(address _fromAtm, address _debitBankAtm, address _creditBankAtm,  string _trxHash, int256 _amount, int256 _fee, int _status);
    function BTM(){       
        
    }
    //the function to be called by an ATM node to start the transaction
    //_debitBank and _debitAccount must be valid, otherwise it has no point for transaction come to blockchain
    // the fee is defined by the _fromAtm because it's the _fromAtm to receive the fee
    //_trxHash include like fromAccout / to account / pwd , such as {from：＂１２３“， to: "456", pwd: "12345"}
    function startTrx(address _fromAtm, string _debitBank, string _creditBank,string _trxHash, int256 _amount, int256 _fee) external{
        
        if(bytes(_debitBank).length == 0){//no debit bank means _debitBank = _fromAtm, like CDP, just to start confirmDebit
            confirmDebit(_fromAtm,_fromAtm, _creditBank, _trxHash, _amount, _fee,STATUS_OK);
        }else{
            var _debitBankAtm = getDestNode(_debitBank);//find an ATM node from the _debitBank
            CheckDebit(_fromAtm,  _debitBankAtm,  _creditBank,  _trxHash,   _amount,  _fee);
        }
        
    }
    //to be called by the credit bank ATM node to confirm that it's ok to be creditted for the transaction
    //pls note that this function require _debitBank address, but not _debitBankAtm
    function confirmDebit(address _fromAtm, address _debitBankAtm, string _creditBank, string _trxHash, int256 _amount, int256 _fee, int _status) public{

        if(_status == STATUS_OK){
            //do nth but wait to check credit information
        }else{//no need to check credit, can commit transaction now (rejection)
            confirmCredit( _fromAtm,  _debitBankAtm,  _fromAtm,  _trxHash,   _amount,  _fee, false, _status);//no credit acc
        }

        if(bytes(_creditBank).length == 0){//no credit bank - like CWD, just to start confirmCredit
            confirmCredit( _fromAtm,  _debitBankAtm,  _fromAtm,  _trxHash,   _amount,  _fee, true, _status);//no credit bank means _creditBankAtm = _fromAtm
        }else{
            var _creditBankAtm = getDestNode(_creditBank);//find an ATM node from the _creditBank
            CheckCredit( _fromAtm,  _debitBankAtm,  _creditBankAtm, _trxHash,   _amount,  _fee);
        }
        

    }
    //pls note that this function require _creditBank address, but not _creditBankAtm
    function confirmCredit(address _fromAtm, address _debitBankAtm, address _creditBankAtm,  string _trxHash, int256 _amount, int256 _fee, bool _feeFrDebitBank, int _status) public{
        if(_status == STATUS_OK){
            
            balanceOf[_debitBankAtm] -= _amount;
            balanceOf[_creditBankAtm] += _amount;
            if(_feeFrDebitBank){
                balanceOf[_debitBankAtm] -= _fee;
            }else{
                balanceOf[_creditBankAtm] -= _fee;
                
            }
            balanceOf[_fromAtm] += _fee;
        }        
        Commit( _fromAtm,  _debitBankAtm,  _creditBankAtm,  _trxHash,   _amount,  _fee, _status);//should tell the _fromAtm abt the debit and credit acc for record

    }
    //struct BankAtms{
    //   mapping (address =>int256) balanceOf;
    //}
    //mapping (address=>BankAtms) bankAtmList;//mapping of bankName - ATMList
    //function addBank(address _bankAdd, string _bankName) external onlyOwner{
    //    balanceOf[_bankAdd] = 0;
    //    nameOf[_bankAdd] = _bankName;
    //}
    function setBankATM(string _bankAdd, address[] _atmAdd) external onlyOwner{
        atmsOf[_bankAdd] = _atmAdd;
    }
    

    function getBankAtms(string _bankAdd) external onlyOwner view returns(address[] s){
        return atmsOf[_bankAdd];
    }
    
    

    //return an ATM node of the selected bank, randomly or load-balanced
    function getDestNode(string _issueBank) internal returns (address dest){
        var index = block.number % atmsOf[_issueBank].length;
        return atmsOf[_issueBank][index];//TODO - need to randomly return a node
    }   
    
    //get balance of any account - can only be called by owner
    function getBalance(address _add) external view onlyOwner returns (int256) {
        return balanceOf[_add];
    }
    
    //return the msg.sender's balance
    function myBalance() external view returns (int256){
        return balanceOf[msg.sender];
    }
    
    //move balance between the 'anAccount' and owner account
    function changeBalance(address anAccount, int256 _amount) external onlyOwner{
        balanceOf[anAccount] += _amount;
        balanceOf[owner] -= _amount;
    }
   
    //testing thing
    function getDate() view returns (uint256 a){
        var s="";
        if(bytes(s).length==0){
            return 3;
        }else{return 1;}
    }
    
    
}
