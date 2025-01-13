// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MitigationContract is ReentrancyGuard {
    address public owner;
    AggregatorV3Interface internal carbonLevelFeed;
    AggregatorV3Interface internal temperatureFeed;

    struct CityData {
        uint256 currentTemperature;
        uint256 targetTemperature;
        uint256 carbonLevel;
        uint256 targetCarbonLevel;
        uint256 lastUpdateTime;
        uint256 deltaFactor;      // δ from your paper
        uint256 mitigationLevel;  // Threshold for climate vulnerable cities
        bool isVulnerable;
        mapping(string => uint256) sectorEmissions; // Sector-wise emissions
    }

    struct RenewalParameters {
        uint256 tickSize;         // ΔT_tick from your paper
        uint256 rewardRate;       // r from your paper
        uint256 salvageValue;     // v from your paper
        uint256 penaltyRate;      // p from your paper
        uint256 discountFactor;   // γ from your paper
    }

    mapping(string => CityData) public cities;
    mapping(address => uint256) public participantCarbonCredits;
    mapping(address => uint256) public participantRewards;
    RenewalParameters public renewalParams;

    // Constants from your research
    uint256 public constant PRECISION = 1e18;
    uint256 public constant BASE_CREDIT_AMOUNT = 100 * PRECISION;
    
    // Events
    event CarbonLevelMeasured(string city, uint256 carbonLevel);
    event TemperatureMeasured(string city, uint256 temperature);
    event CarbonCreditsAdjusted(address participant, uint256 amount);
    event RewardCalculated(address participant, uint256 reward);
    event CityStatusUpdated(string city, bool isVulnerable);
    event MitigationExecuted(string city, uint256 tempReduction, uint256 carbonReduction);

    constructor(
        address _carbonLevelFeed, 
        address _temperatureFeed
    ) {
        owner = msg.sender;
        carbonLevelFeed = AggregatorV3Interface(_carbonLevelFeed);
        temperatureFeed = AggregatorV3Interface(_temperatureFeed);
        
        // Initialize renewal parameters based on your research
        renewalParams = RenewalParameters({
            tickSize: 0.1 * PRECISION,        // 0.1 degree per tick
            rewardRate: 0.05 * PRECISION,     // 5% reward rate
            salvageValue: 0.8 * PRECISION,    // 80% salvage value
            penaltyRate: 0.2 * PRECISION,     // 20% penalty rate
            discountFactor: 0.95 * PRECISION  // 95% discount factor
        });
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Initialize or update city data
    function setCity(
        string memory cityName,
        uint256 currentTemp,
        uint256 targetTemp,
        uint256 carbonLevel,
        uint256 targetCarbon,
        uint256 mitigationLevel
    ) external onlyOwner {
        CityData storage city = cities[cityName];
        city.currentTemperature = currentTemp;
        city.targetTemperature = targetTemp;
        city.carbonLevel = carbonLevel;
        city.targetCarbonLevel = targetCarbon;
        city.mitigationLevel = mitigationLevel;
        city.lastUpdateTime = block.timestamp;
        
        // Evaluate city vulnerability based on your research criteria
        city.isVulnerable = evaluateCityVulnerability(cityName);
        emit CityStatusUpdated(cityName, city.isVulnerable);
    }

    // Calculate required ticks for temperature reduction
    function calculateRequiredTicks(string memory cityName) public view returns (uint256) {
        CityData storage city = cities[cityName];
        if (city.currentTemperature <= city.targetTemperature) return 0;
        
        return ((city.currentTemperature - city.targetTemperature) * PRECISION) / renewalParams.tickSize;
    }

    // Calculate total cost using your research formula
    function calculateTotalCost(string memory cityName) public view returns (uint256) {
        CityData storage city = cities[cityName];
        uint256 annualEmissionReduction = (city.carbonLevel - city.targetCarbonLevel);
        uint256 temperatureDelta = (city.currentTemperature - city.targetTemperature);
        
        // C_total = ΔE_annual * Price * t = α * (T_current - T_target) * Price
        return (annualEmissionReduction * temperatureDelta * getCurrentPrice()) / PRECISION;
    }

    // Execute mitigation based on renewal theory
    function executeMitigation(string memory cityName) external nonReentrant returns (bool) {
        CityData storage city = cities[cityName];
        require(city.lastUpdateTime > 0, "City not initialized");
        
        uint256 timePassed = block.timestamp - city.lastUpdateTime;
        uint256 ticks = timePassed / 1 days; // Daily ticks
        
        if (ticks == 0) return false;
        
        // Calculate reductions using renewal theory
        uint256 tempReduction = calculateTemperatureReduction(cityName, ticks);
        uint256 carbonReduction = calculateCarbonReduction(cityName, ticks);
        
        // Apply reductions
        if (city.currentTemperature > city.targetTemperature) {
            city.currentTemperature -= tempReduction;
        }
        if (city.carbonLevel > city.targetCarbonLevel) {
            city.carbonLevel -= carbonReduction;
        }
        
        // Update city status
        city.lastUpdateTime = block.timestamp;
        city.isVulnerable = evaluateCityVulnerability(cityName);
        
        emit MitigationExecuted(cityName, tempReduction, carbonReduction);
        emit CityStatusUpdated(cityName, city.isVulnerable);
        
        return true;
    }

    // Calculate temperature reduction using renewal theory
    function calculateTemperatureReduction(string memory cityName, uint256 ticks) internal view returns (uint256) {
        CityData storage city = cities[cityName];
        uint256 maxReduction = (city.currentTemperature - city.targetTemperature);
        uint256 theoreticalReduction = ticks * renewalParams.tickSize;
        
        return theoreticalReduction < maxReduction ? theoreticalReduction : maxReduction;
    }

    // Calculate carbon reduction based on temperature reduction
    function calculateCarbonReduction(string memory cityName, uint256 ticks) internal view returns (uint256) {
        CityData storage city = cities[cityName];
        uint256 baseReduction = (city.carbonLevel * ticks * renewalParams.rewardRate) / PRECISION;
        
        if (city.isVulnerable) {
            baseReduction = (baseReduction * (PRECISION + renewalParams.penaltyRate)) / PRECISION;
        }
        
        return baseReduction;
    }

    // Evaluate if a city is climate vulnerable based on your research criteria
    function evaluateCityVulnerability(string memory cityName) internal view returns (bool) {
        CityData storage city = cities[cityName];
        
        // City is vulnerable if it exceeds either threshold
        bool temperatureExceeded = city.currentTemperature > city.targetTemperature;
        bool carbonExceeded = city.carbonLevel > city.targetCarbonLevel;
        
        return temperatureExceeded || carbonExceeded;
    }

    // Calculate rewards using your renewal reward theorem
    function calculateReward(address participant, uint256 interactions) public {
        uint256 carbonCredits = participantCarbonCredits[participant];
        
        // R(t) = (m(t) + 1)E[R] - E[R_N(t)+1]
        uint256 baseReward = (interactions + 1) * carbonCredits;
        uint256 discountedReward = (baseReward * renewalParams.discountFactor) / PRECISION;
        
        participantRewards[participant] += discountedReward;
        emit RewardCalculated(participant, discountedReward);
    }

    // Helper function to get current carbon credit price
    function getCurrentPrice() internal view returns (uint256) {
        (, int256 price,,,) = carbonLevelFeed.latestRoundData();
        return uint256(price);
    }

    // Getter functions
    function getCityData(string memory cityName) external view returns (
        uint256 currentTemp,
        uint256 targetTemp,
        uint256 carbonLevel,
        uint256 targetCarbon,
        bool isVulnerable
    ) {
        CityData storage city = cities[cityName];
        return (
            city.currentTemperature,
            city.targetTemperature,
            city.carbonLevel,
            city.targetCarbonLevel,
            city.isVulnerable
        );
    }
}
