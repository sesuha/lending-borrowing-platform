// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract LendingBorrowingPlatform {
    
    struct Lender {
        uint amountLent;
        uint interestRate;
        uint lendingStart;
    }
    
    struct Borrower {
        uint amountBorrowed;
        uint collateralAmount;
        uint borrowStart;
        bool hasRepaid;
    }
    
    address public admin; 
    
    mapping(address => Lender) public lenders;
    mapping(address => Borrower) public borrowers;
    
    uint public totalLendingPool;
    
    event Lend(address indexed lender, uint amount);
    event Borrow(address indexed borrower, uint amount);
    event Repay(address indexed borrower, uint amount);
    event Withdraw(address indexed lender, uint amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function lend(uint _interestRate) external payable {
        require(msg.value > 0, "Lending amount must be greater than zero");
        require(lenders[msg.sender].amountLent == 0, "Already lent assets");
        
        lenders[msg.sender] = Lender({
            amountLent: msg.value,
            interestRate: _interestRate,
            lendingStart: block.timestamp
        });
        
        totalLendingPool += msg.value;
        
        emit Lend(msg.sender, msg.value);
    }
    
    function borrow() external payable {
        require(msg.value > 0, "Collateral must be greater than zero");
        require(borrowers[msg.sender].amountBorrowed == 0, "Already borrowed assets");
        
        uint borrowAmount = msg.value / 2;
        
        require(borrowAmount <= totalLendingPool, "Not enough liquidity in the pool");
        
        totalLendingPool -= borrowAmount;
        
        borrowers[msg.sender] = Borrower({
            amountBorrowed: borrowAmount,
            collateralAmount: msg.value,
            borrowStart: block.timestamp,
            hasRepaid: false
        });
        
        payable(msg.sender).transfer(borrowAmount);
        
        emit Borrow(msg.sender, borrowAmount);
    }
    
    function repay() external payable {
        Borrower storage borrower = borrowers[msg.sender];
        require(borrower.amountBorrowed > 0, "No loan to repay");
        require(!borrower.hasRepaid, "Loan already repaid");
        require(msg.value == borrower.amountBorrowed, "Incorrect repayment amount");
        
        borrower.hasRepaid = true;
        
        payable(msg.sender).transfer(borrower.collateralAmount);
        
        totalLendingPool += msg.value;
        
        emit Repay(msg.sender, msg.value);
    }
    
    function withdraw() external {
        Lender storage lender = lenders[msg.sender];
        require(lender.amountLent > 0, "No assets to withdraw");
        
        uint timeLent = block.timestamp - lender.lendingStart;
        uint interest = (lender.amountLent * lender.interestRate * timeLent) / (365 days * 100);
        
        uint totalAmount = lender.amountLent + interest;
        
        require(totalAmount <= totalLendingPool, "Not enough funds to withdraw");
        
        totalLendingPool -= totalAmount;
        
        payable(msg.sender).transfer(totalAmount);
        
        emit Withdraw(msg.sender, totalAmount);
        
        lender.amountLent = 0;
        lender.interestRate = 0;
        lender.lendingStart = 0;
    }
    
    function getLendingPoolBalance() external view returns (uint) {
        return totalLendingPool;
    }
}
