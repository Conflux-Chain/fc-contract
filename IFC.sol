pragma solidity ^0.5.0;

interface IFC
{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Lock(address indexed account, uint256 value);
    event Write(address indexed account, uint256 CPool, uint256 PPool, uint256 PPoolLocked);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function stateOf(address account) external view returns (uint256, uint256, uint256);
    function circulationRatio() external view returns (uint256);

    function setTotalSupply(uint256 total) external;
    function setStateOf(address account, uint256 ConfluxPool, uint256 PersonalPool, uint256 PersonalLocked) external;
    function setCirculationRatio(uint256 value) external;
    function transfer(address recipient, uint256 value) external returns (bool);
    function mint(address account, uint256 value) external returns (bool);
    function burn(uint256 value) external;
}