// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @title A implementation of ERC20
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @author 0xfave
/// @notice ERC20 token
/// @dev https://eips.ethereum.org/EIPS/eip-20
contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // balance
    mapping(address => uint256) balances;
    // approve
    mapping(address => mapping(address => uint256)) allowances;

    // event
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _mint(msg.sender, totalSupply_);
    }

    /// @notice Returns the balance of the given address.
    /// @param _address The address to check the balance of.
    /// @return balance The balance of the given address.
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }

    /// @notice Transfers tokens from the caller's account to the specified address.
    /// @param _to The address to transfer tokens to.
    /// @param _value The amount of tokens to transfer.
    /// @return success A boolean indicating whether the transfer was successful.
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_value > balances[msg.sender]) revert("ERC20: transfer amount exceeds balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfers tokens from the specified address to the specified address.
    /// @param _from The address to transfer tokens from.
    /// @param _to The address to transfer tokens to.
    /// @param _value The amount of tokens to transfer.
    /// @return success A boolean indicating whether the transfer was successful.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_value > balances[_from]) revert("ERC20: transfer amount exceeds balance");
        // checks for allowances
        require(allowances[_from][msg.sender] >= _value, "ERC20: insufficient allowance");
        allowances[_from][msg.sender] -= _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Approves the specified address to spend the specified amount of tokens on behalf of the caller.
    /// @param _spender The address to approve.
    /// @param _value The amount of tokens to approve.
    /// @return success A boolean indicating whether the approval was successful.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Returns the amount of tokens that the `_spender` is still allowed to withdraw from the `_owner`.
    /// @param _owner The owner of the tokens.
    /// @param _spender The address that is allowed to spend the tokens.
    /// @return remaining The amount of tokens the `_spender` is still allowed to withdraw.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    /// @notice Mints new tokens and adds them to the specified account's balance.
    /// @param account The address to mint the tokens to.
    /// @param amount The amount of tokens to mint.
    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        balances[account] += amount;
    }
}
