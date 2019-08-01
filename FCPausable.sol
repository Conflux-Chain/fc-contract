pragma solidity ^0.5.0;

import "./FCRoles.sol";

contract FCPausable is FCRoles {
    event TransferPaused(address account);
    event TransferUnpaused(address account);

    event BurnPaused(address account);
    event BurnUnpaused(address account);

    event MigratePaused(address account);
    event MigrateUnpaused(address account);

    bool private _transferPaused;
    bool private _burnPaused;
    bool private _migratePaused;

    constructor () internal
    {
        _transferPaused = false;
        _burnPaused = true;
        _migratePaused = true;
    }

    // IsPaused
    function isTransferPaused() public view returns (bool) {
        return _transferPaused;
    }

    function isBurnPaused() public view returns (bool) {
        return _burnPaused;
    }

    function isMigratePaused() public view returns (bool) {
        return _migratePaused;
    }

    // WhenNotPaused
    modifier whenTransferNotPaused() {
        require(!_transferPaused, "Pausable: Transfer paused");
        _;
    }

    modifier whenBurnNotPaused() {
        require(!_burnPaused, "Pausable: Burn paused");
        _;
    }

    modifier whenMigrateNotPaused() {
        require(!_migratePaused, "Pausable: Migrate paused");
        _;
    }

    // WhenPaused
    modifier whenTransferPaused() {
        require(_transferPaused, "Pausable: Transfer not paused");
        _;
    }

    modifier whenBurnPaused() {
        require(_burnPaused, "Pausable: Burn not paused");
        _;
    }

    modifier whenMigratePaused() {
        require(_migratePaused, "Pausable: Migrate not paused");
        _;
    }

    // Pause
    function pauseTransfer() internal {
        _transferPaused = true;
        emit TransferPaused(msg.sender);
    }

    function pauseBurn() internal {
        _burnPaused = true;
        emit BurnPaused(msg.sender);
    }

    function pauseMigrate() internal {
        _migratePaused = true;
        emit MigratePaused(msg.sender);
    }

    // Unpause
    function unpauseTransfer() internal {
        _transferPaused = false;
        emit TransferUnpaused(msg.sender);
    }

    function unpauseBurn() internal {
        _burnPaused = false;
        emit BurnUnpaused(msg.sender);
    }

    function unpauseMigrate() internal {
        _migratePaused = false;
        emit MigrateUnpaused(msg.sender);
    }

    // Before Migration
    function pauseBeforeMigration() public onlyPauser {
        pauseTransfer();
        pauseBurn();
        pauseMigrate();
    }

    // During Migration
    function pauseDuringMigration() public onlyPauser {
        pauseTransfer();
        pauseBurn();
        unpauseMigrate();
    }

    // After Initialization
    function pauseAfterInitialization() public onlyPauser {
        unpauseTransfer();
        pauseBurn();
        pauseMigrate();
    }

    // For Exchange
    function pauseForExchange() public onlyPauser {
        pauseTransfer();
        unpauseBurn();
        pauseMigrate();
    }
}