// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Base contract for handling renewal theory calculations
contract RenewalTheoryContract {
    using SafeMath for uint256;

    struct SectorData {
        uint256 value;
        uint256 timestamp;
        uint256 totalRenewals;
        uint256[] renewalTimes;
        uint256[] creditAmounts;
        uint256 cumulativeReduction;
    }

    struct CityData {
        mapping(string => SectorData) sectors;
        uint256 baseAllowance;
        uint256 seasonalFactor;
        uint256 emergencyBuffer;
        uint256 lastCalculationTime;
    }

    mapping(string => CityData) public cities;

    // Constants
    uint256 public constant MIN_RENEWAL_INTERVAL = 1 days;
    uint256 public constant MAX_RENEWAL_RATE = 365; // Daily data
    uint256 public constant BASE_IMPACT = 100; // 1 unit in basis points
    uint256 public constant SEASONAL_VARIATION = 20; // 20% seasonal variation

    event RenewalProcessed(string city, string sector, uint256 timestamp, uint256 credits);
    event AllowanceUpdated(string city, uint256 newAllowance);
    event ReductionRecorded(string city, string sector, uint256 reduction);

    function initializeCity(string memory city, uint256 baseAllowance) external {
        require(cities[city].baseAllowance == 0, "City already initialized");
        
        cities[city].baseAllowance = baseAllowance;
        cities[city].seasonalFactor = 100;
        cities[city].emergencyBuffer = baseAllowance.div(10);
        cities[city].lastCalculationTime = block.timestamp;
    }

    function recordSectorValue(
        string memory city,
        string memory sector,
        uint256 value,
        uint256 timestamp
    ) external {
        require(cities[city].baseAllowance != 0, "City not initialized");
        
        SectorData storage sectorData = cities[city].sectors[sector];
        sectorData.value = value;
        sectorData.timestamp = timestamp;
        
        processRenewal(city, sector);
    }

    function processRenewal(string memory city, string memory sector) internal {
        SectorData storage sectorData = cities[city].sectors[sector];
        
        if (canRenew(city, sector)) {
            uint256 credits = calculateCreditAmount(city, sector);
            uint256 reduction = calculateReduction(credits);

            sectorData.totalRenewals = sectorData.totalRenewals.add(1);
            sectorData.renewalTimes.push(block.timestamp);
            sectorData.creditAmounts.push(credits);
            sectorData.cumulativeReduction = sectorData.cumulativeReduction.add(reduction);

            emit RenewalProcessed(city, sector, block.timestamp, credits);
            emit ReductionRecorded(city, sector, reduction);
        }
    }

    function canRenew(string memory city, string memory sector) public view returns (bool) {
        SectorData storage sectorData = cities[city].sectors[sector];
        
        if (sectorData.totalRenewals == 0) return true;
        
        uint256 lastRenewalTime = sectorData.renewalTimes[sectorData.renewalTimes.length - 1];
        uint256 timeSinceLastRenewal = block.timestamp.sub(lastRenewalTime);
        
        return timeSinceLastRenewal >= MIN_RENEWAL_INTERVAL;
    }

    function calculateCreditAmount(string memory city, string memory sector) public view returns (uint256) {
        CityData storage cityData = cities[city];
        SectorData storage sectorData = cityData.sectors[sector];
        
        uint256 baseAmount = cityData.baseAllowance.mul(cityData.seasonalFactor).div(100);
        
        if (isEmergencyCondition(city, sector)) {
            baseAmount = baseAmount.add(cityData.emergencyBuffer);
        }
        
        return baseAmount.mul(sectorData.value);
    }

    function calculateReduction(uint256 credits) public pure returns (uint256) {
        return credits.mul(BASE_IMPACT).div(1e4);
    }

    function isEmergencyCondition(string memory city, string memory sector) public view returns (bool) {
        SectorData storage sectorData = cities[city].sectors[sector];
        return sectorData.value > 0.001 ether; // Example threshold
    }
}

contract CarbonCreditMarket is RenewalTheoryContract, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapRouter;
    address public carbonCreditToken;
    address public usdToken;

    struct CompanyData {
        bool isRegistered;
        uint256 carbonCredits;
        bool isBuying;
        bool isSelling;
    }

    mapping(address => CompanyData) public companies;
    address[] public buyersList;
    address[] public sellersList;

    constructor(
        address _uniswapRouter,
        address _carbonCreditToken,
        address _usdToken
    ) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        carbonCreditToken = _carbonCreditToken;
        usdToken = _usdToken;
    }

    function registerCompany(address company) external onlyOwner {
        require(!companies[company].isRegistered, "Company already registered");
        companies[company].isRegistered = true;
    }

    function wantToBuy() external {
        require(companies[msg.sender].isRegistered, "Company not registered");
        require(!companies[msg.sender].isBuying, "Already in buyers list");
        
        companies[msg.sender].isBuying = true;
        buyersList.push(msg.sender);
    }

    function wantToSell() external {
        require(companies[msg.sender].isRegistered, "Company not registered");
        require(!companies[msg.sender].isSelling, "Already in sellers list");
        
        companies[msg.sender].isSelling = true;
        sellersList.push(msg.sender);
    }

    function trade(
        address buyer,
        address seller,
        uint256 carbonCredits,
        uint256 usdAmount,
        string memory city,
        string memory sector
    ) external onlyOwner {
        require(companies[buyer].isBuying, "Buyer not interested");
        require(companies[seller].isSelling, "Seller not interested");
        
        SectorData storage sectorData = cities[city].sectors[sector];
        require(carbonCredits.mul(4) > sectorData.cumulativeReduction.mul(3), "Insufficient carbon credits");

        // Handle token transfers
        IERC20(carbonCreditToken).transferFrom(seller, buyer, carbonCredits);
        
        // Perform Uniswap swap
        address[] memory path = new address[](2);
        path[0] = carbonCreditToken;
        path[1] = usdToken;
        
        uniswapRouter.swapExactTokensForTokens(
            carbonCredits,
            usdAmount,
            path,
            address(this),
            block.timestamp
        );

        IERC20(usdToken).transfer(seller, usdAmount);
        
        // Update company status
        removeFromList(buyer, buyersList);
        removeFromList(seller, sellersList);
        companies[buyer].isBuying = false;
        companies[seller].isSelling = false;
    }

    function removeFromList(address company, address[] storage list) internal {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == company) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }
}
