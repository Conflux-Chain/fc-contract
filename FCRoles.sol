pragma solidity ^0.5.0;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/Roles.sol";

contract FCRoles {
    using Roles for Roles.Role;
    Roles.Role private _minters;
    Roles.Role private _pausers;
    Roles.Role private _admins;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    //---------- Admin Begin ---------//
    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "AdminRole: caller does not have the Admin role");
        _;
    }

    function onlyAdminMock() public view onlyAdmin {
        // solhint-disable-previous-line no-empty-blocks
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
    //---------- Admin End ---------//

    //---------- Minter Begin ---------//
    modifier onlyMinter() {
        require(isMinter(msg.sender) || isAdmin(msg.sender), "MinterRole: caller does not have the Minter role or above");
        _;
    }

    function onlyMinterMock() public view onlyMinter {
        // solhint-disable-previous-line no-empty-blocks
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyAdmin {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyAdmin {
        _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
    //---------- Minter End ---------//

    //---------- Pauser Begin ---------//
    modifier onlyPauser() {
        require(isPauser(msg.sender) || isAdmin(msg.sender), "PauserRole: caller does not have the Pauser role or above");
        _;
    }

    function onlyPauserMock() public view onlyPauser {
        // solhint-disable-previous-line no-empty-blocks
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyAdmin {
        _addPauser(account);
    }

    function removePauser(address account) public onlyAdmin {
        _removePauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
    //---------- Pauser End ---------//
}