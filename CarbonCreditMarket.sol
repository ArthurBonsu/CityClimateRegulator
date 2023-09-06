// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/CompanyRegister.sol";

contract CarbonCreditMarket is CompanyRegister, Ownable  {
    IUniswapV2Router02 public uniswapRouter;
    address public carbonCreditToken; // The address of the ERC20 token representing carbon credits
    address public usdToken; // The address of the USD or other asset token

    // Arrays and mappings to keep track of companies interested in buying and selling
    address[] public companiesWantToBuy;
    address[] public companiesWantToSell;
    mapping(address => bool) public isBuying;
    mapping(address => bool) public isSelling;

    constructor(
        address _uniswapRouter,
        address _carbonCreditToken,
        address _usdToken
    ) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        carbonCreditToken = _carbonCreditToken;
        usdToken = _usdToken;
    }

    // Function for companies to indicate interest in buying carbon credits
    function wantToBuy() external {
        require (registeredCompanies[msg.sender] == true); 
        companiesWantToBuy.push(msg.sender);
        isBuying[msg.sender] = true;
    }

    // Function for companies to indicate interest in selling carbon credits
    function wantToSell() external {
        require (registeredCompanies[msg.sender] == true); 
        companiesWantToSell.push(msg.sender);
        isSelling[msg.sender] = true;
    }

    // Function for companies to trade carbon credits with USD
    function trade(address buyer, address seller, uint256 carbonCredits, uint256 usdAmount) external onlyOwner {
        require(isBuying[buyer], "Buyer not interested in buying");
        require(isSelling[seller], "Seller not interested in selling");

        // Transfer carbon credits from seller to buyer
        IERC20(carbonCreditToken).transferFrom(seller, buyer, carbonCredits);

        // Perform the swap on Uniswap V2
        address[] memory path = new address[](2);
        path[0] = carbonCreditToken; // Carbon credits
        path[1] = usdToken; // USD

        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            carbonCredits,
            usdAmount,
            path,
            address(this),
            block.timestamp
        );

        // Verify that the swap was successful (check amounts array)

        // Transfer USD from buyer to seller
        IERC20(usdToken).transfer(seller, usdAmount);

        // Remove companies from the buy and sell lists
        removeCompany(buyer, companiesWantToBuy);
        removeCompany(seller, companiesWantToSell);
    }

    // Function to remove a company from the list
    function removeCompany(address company, address[] storage list) internal {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == company) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }
}

