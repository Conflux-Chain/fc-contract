pragma solidity ^0.5.0;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./IFC.sol";
import "./FCPausable.sol";

contract FC is IFC, FCPausable
{
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _cap;
    uint256 private _totalSupply;
    uint256 private _circulationRatio; // For r units of FC, lock 100 FC
    mapping (address => uint256) private _confluxBalances; // Conflux Pool
    mapping (address => uint256) private _personalBalances; // Personal Pool
    mapping (address => uint256) private _personalLockedBalances; // Personal Locked Pool

    mapping (address => bool) private _accountCheck;
    address[] private _accountList;

    constructor()
        FCPausable()
        public
    {
        _name = "FansCoin";
        _symbol = "FC";
        _decimals = 18;
        _circulationRatio = 100;
        uint256 fc_cap = 100000000;
        _cap = fc_cap.mul(10 ** uint256(_decimals));
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return (_confluxBalances[account] + _personalBalances[account] + _personalLockedBalances[account]);
    }

    function circulationRatio() public view returns (uint256) {
        return _circulationRatio;
    }

    function stateOf(address account) public view returns (uint256, uint256, uint256) {
        return (_confluxBalances[account], _personalBalances[account], _personalLockedBalances[account]);
    }

    //---------------- Data Migration ----------------------
    function accountTotal() public view returns (uint256) {
        return _accountList.length;
    }

    function accountList(uint256 begin) public view returns (address[100] memory) {
        require(begin >= 0 && begin < _accountList.length, "FC: accountList out of range");
        address[100] memory res;
        uint256 range = _min(_accountList.length, begin + 100);
        for (uint256 i = begin; i < range; i++) {
            res[i-begin] = _accountList[i];
        }
        return res;
    }

    function setStateOf(address account, uint256 ConfluxPool, uint256 Personal, uint256 Locked) public onlyPauser whenMigrateNotPaused {
        require(account != address(0), "FC: Migration to the zero address");

        if (!_accountCheck[account]) {
            _accountCheck[account] = true;
            _accountList.push(account);
        }

        _confluxBalances[account] = ConfluxPool;
        _personalBalances[account] = Personal;
        _personalLockedBalances[account] = Locked;

        emit Write(account, ConfluxPool, Personal, Locked);
    }

    function setTotalSupply(uint256 total) public onlyPauser whenMigrateNotPaused {
        _totalSupply = total;
    }
    //---------------- End Data Migration ----------------------
    function setCirculationRatio(uint256 value) public onlyAdmin {
        _circulationRatio = value;
    }

    function mint(address account, uint256 value) public onlyMinter returns (bool) {
        if (!_accountCheck[account]) {
            _accountCheck[account] = true;
            _accountList.push(account);
        }

        _mint(account, value);
        return true;
    }

    function transfer(address recipient, uint256 value) public whenTransferNotPaused returns (bool) {
        require(recipient != address(0), "FC: transfer to the zero address");

        if (!_accountCheck[recipient]) {
            _accountCheck[recipient] = true;
            _accountList.push(recipient);
        }

        // If the given amount is greater than
        // the unlocked balance of the sender, revert
        _confluxBalances[msg.sender].add(_personalBalances[msg.sender].mul(_circulationRatio).div(_circulationRatio + 100)).sub(value);

        // Favor Conflux Pool due to the lack of circulation restriction
        if (value <= _confluxBalances[msg.sender]) {
            _transferC2P(msg.sender, recipient, value);
        } else {
            _transferP2P(msg.sender, recipient, value.sub(_confluxBalances[msg.sender]));
            _transferC2P(msg.sender, recipient, _confluxBalances[msg.sender]);
        }

        emit Transfer(msg.sender, recipient, value);
        return true;
    }

    function burn(uint256 value) public whenBurnNotPaused {
        require(msg.sender != address(0), "FC: burn from the zero address");
        // If the given amount is greater than
        // the balance of the sender, revert
        _confluxBalances[msg.sender].add(_personalBalances[msg.sender]).add(_personalLockedBalances[msg.sender]).sub(value);

        // Personal Locked Pool > Personal Pool > Conflux Pool
        _burnCPool(msg.sender, value > _personalBalances[msg.sender].add(_personalLockedBalances[msg.sender]) ?
            _min(value.sub(_personalLockedBalances[msg.sender]).sub(_personalBalances[msg.sender]), _confluxBalances[msg.sender]) : 0);

        _burnPPool(msg.sender, value > _personalLockedBalances[msg.sender] ?
            _min(value.sub(_personalLockedBalances[msg.sender]), _personalBalances[msg.sender]): 0);

        _burnPPoolLocked(msg.sender, _min(value, _personalLockedBalances[msg.sender]));

        emit Transfer(msg.sender, address(0), value);
    }

    //---------- Helper Begin ----------//
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "FC: mint to the zero address");
        require(totalSupply().add(value) <= _cap, "FC: cap exceeded");

        _totalSupply = _totalSupply.add(value);
        _confluxBalances[account] = _confluxBalances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _transferC2P(address sender, address recipient, uint256 value) internal {
        require(sender != address(0), "FC: transfer from the zero address");
        require(recipient != address(0), "FC: transfer to the zero address");

        _confluxBalances[sender] = _confluxBalances[sender].sub(value);
        _personalBalances[recipient] = _personalBalances[recipient].add(value);
    }

    function _transferP2P(address sender, address recipient, uint256 value) internal {
        require(sender != address(0), "FC: transfer from the zero address");
        require(recipient != address(0), "FC: transfer to the zero address");

        uint256 lockedAmount = _max(value.mul(100).div(_circulationRatio), 1);

        // Spend: -(value + value * 100 / r)
        _personalBalances[sender] = _personalBalances[sender].sub(value.add(lockedAmount));

        // Lock: + value * 100 / r, at least 1
        _personalLockedBalances[sender] = _personalLockedBalances[sender].add(lockedAmount);

        // Transfer: +value
        _personalBalances[recipient] = _personalBalances[recipient].add(value);

        emit Lock(sender, _max(value.mul(100).div(_circulationRatio), 1));
    }

    function _burnPPoolLocked(address account, uint256 value) internal {
        require(account != address(0), "FC: burn from the zero address");
        _personalLockedBalances[account] = _personalLockedBalances[account].sub(value);
        _totalSupply = _totalSupply.sub(value);
    }

    function _burnPPool(address account, uint256 value) internal {
        require(account != address(0), "FC: burn from the zero address");
        _personalBalances[account] = _personalBalances[account].sub(value);
        _totalSupply = _totalSupply.sub(value);
    }

    function _burnCPool(address account, uint256 value) internal {
        require(account != address(0), "FC: burn from the zero address");
        _confluxBalances[account] = _confluxBalances[account].sub(value);
        _totalSupply = _totalSupply.sub(value);
    }

    function _min(uint256 value1, uint256 value2) internal pure returns (uint256) {
        if (value1 > value2) {
            return value2;
        }
        return value1;
    }

    function _max(uint256 value1, uint256 value2) internal pure returns (uint256) {
        if (value1 < value2) {
            return value2;
        }
        return value1;
    }
    //---------- Helper End ------------//
}