// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool is Ownable {
    struct Pool {
        IERC20 token;
        uint256 totalSupply;
        uint256 totalBorrowed;
        uint256 interestRate; // annual interest rate
        mapping(address => uint256) balances;
        mapping(address => uint256) borrows;
    }

    Pool[] public pools;

    // Pass the owner address to the Ownable constructor
    constructor(address owner) Ownable(owner) {}

    function addPool(address _token, uint256 _interestRate) external onlyOwner {
        Pool storage newPool = pools.push();
        newPool.token = IERC20(_token);
        newPool.totalSupply = 0;
        newPool.totalBorrowed = 0;
        newPool.interestRate = _interestRate;
    }

    function deposit(uint256 _poolId, uint256 _amount) external {
        Pool storage pool = pools[_poolId];
        require(_amount > 0, "Amount must be greater than zero");
        pool.token.transferFrom(msg.sender, address(this), _amount);
        pool.balances[msg.sender] += _amount;
        pool.totalSupply += _amount;
    }

    function withdraw(uint256 _poolId, uint256 _amount) external {
        Pool storage pool = pools[_poolId];
        require(pool.balances[msg.sender] >= _amount, "Insufficient balance");
        pool.balances[msg.sender] -= _amount;
        pool.totalSupply -= _amount;
        pool.token.transfer(msg.sender, _amount);
    }

    // function borrow(uint256 _poolId, uint256 _amount) external {
    //     Pool storage pool = pools[_poolId];
    //     require(_amount > 0 && _amount <= (pool.totalSupply - pool.totalBorrowed), "Invalid borrow amount");
    //     pool.borrows[msg.sender] += _amount;
    //     pool.totalBorrowed += _amount;
    //     pool.token.transfer(msg.sender, _amount);
    // }

    function borrow(uint256 _poolId, uint256 _amount) external {
        Pool storage pool = pools[_poolId];
        uint256 availableAmount = pool.totalSupply - pool.totalBorrowed;
        require(_amount > 0 && _amount <= availableAmount, "Invalid borrow amount");
    
        pool.borrows[msg.sender] += _amount;
        pool.totalBorrowed += _amount;
        pool.token.transfer(msg.sender, _amount);
    
        emit BorrowingDebug(pool.totalSupply, pool.totalBorrowed, availableAmount);
    }

event BorrowingDebug(uint256 totalSupply, uint256 totalBorrowed, uint256 availableAmount);

    function repay(uint256 _poolId, uint256 _amount) external {
        Pool storage pool = pools[_poolId];
        require(pool.borrows[msg.sender] >= _amount, "Invalid repay amount");
        pool.borrows[msg.sender] -= _amount;
        pool.totalBorrowed -= _amount;
        pool.token.transferFrom(msg.sender, address(this), _amount);
    }
    function listPools() external view returns (uint256[] memory) {
    uint256[] memory poolIds = new uint256[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            poolIds[i] = i;
        }
        return poolIds;
    }
}