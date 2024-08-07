// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MitigationContract {
    address public owner;
    AggregatorV3Interface internal carbonLevelFeed;
    AggregatorV3Interface internal temperatureFeed;

    uint256 public carbonThreshold;
    uint256 public temperatureThreshold;

    mapping(address => uint256) public participantCarbonCredits;
    mapping(address => uint256) public participantRewards;

    event CarbonLevelMeasured(uint256 carbonLevel);
    event TemperatureMeasured(uint256 temperature);
    event CarbonCreditsAdjusted(address participant, uint256 amount);
    event RewardCalculated(address participant, uint256 reward);

    constructor(address _carbonLevelFeed, address _temperatureFeed) {
        owner = msg.sender;
        carbonLevelFeed = AggregatorV3Interface(_carbonLevelFeed);
        temperatureFeed = AggregatorV3Interface(_temperatureFeed);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setThresholds(uint256 _carbonThreshold, uint256 _temperatureThreshold) public onlyOwner {
        carbonThreshold = _carbonThreshold;
        temperatureThreshold = _temperatureThreshold;
    }

    function measureCarbonLevel() public returns (uint256) {
        (, int256 carbonLevel, , ,) = carbonLevelFeed.latestRoundData();
        uint256 carbonLevelUint = uint256(carbonLevel);
        emit CarbonLevelMeasured(carbonLevelUint);
        return carbonLevelUint;
    }

    function measureTemperature() public returns (uint256) {
        (, int256 temperature, , ,) = temperatureFeed.latestRoundData();
        uint256 temperatureUint = uint256(temperature);
        emit TemperatureMeasured(temperatureUint);
        return temperatureUint;
    }

    function calculateCarbonCredits(uint256 carbonLevel, uint256 temperature) public view returns (uint256) {
        uint256 carbonCreditNeeded = 0;
        if (carbonLevel > carbonThreshold || temperature > temperatureThreshold) {
            carbonCreditNeeded = (carbonLevel - carbonThreshold) + (temperature - temperatureThreshold);
        }
        return carbonCreditNeeded;
    }

    function adjustCarbonCredits(address participant) public {
        uint256 carbonLevel = measureCarbonLevel();
        uint256 temperature = measureTemperature();
        uint256 carbonCredits = calculateCarbonCredits(carbonLevel, temperature);
        participantCarbonCredits[participant] += carbonCredits;
        emit CarbonCreditsAdjusted(participant, carbonCredits);
    }

    function calculateReward(address participant, uint256 interactions) public {
        uint256 reward = interactions * participantCarbonCredits[participant]; // Simplified reward calculation
        participantRewards[participant] += reward;
        emit RewardCalculated(participant, reward);
    }

    function getCarbonCredits(address participant) public view returns (uint256) {
        return participantCarbonCredits[participant];
    }

    function getRewards(address participant) public view returns (uint256) {
        return participantRewards[participant];
    }
}
