// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CityRegister is ERC20, Ownable {

  uint256 private payfee; 
    struct City {
        string name;
        string location;
        uint256 longitude;
        uint256 latitude;
        uint256 carbonCapacity;
        uint256 amountPaid;
        uint256 cityCountId;
    }

    mapping(address => City) public cityStore;
    mapping(address => bool) public registeredCities;
    mapping(address => bool) public paidCityEscrowFee;

    mapping(address => uint256) public carbonLevels;
    mapping(address => uint256) public maxCreditLevels;
      mapping(address => uint256) public carboncredit;

    constructor() ERC20("RPSTOKENS", "RPS") {
        _mint(msg.sender, 1000000 * 10 ** 18); // Mint 1,000,000 RPS tokens to the contract creator
    }

    function payFee(address payable cityAddress, uint256 amount) external payable {
        require(amount >= 10 ether, "Amount must be at least 10 ether");
        require(!paidCityEscrowFee[cityAddress], "Fee already paid for this city");

        (bool success, ) = cityAddress.call{value: amount}("");
        require(success, "Payment failed");

        paidCityEscrowFee[cityAddress] = true;
    }

    function registerCity(
        string memory cityName,
        address payable cityAddress,
        uint256 amount,
        uint256 lng,
        uint256 lat,
        uint256 carbonCapacity
    ) external onlyOwner {
        require(!registeredCities[cityAddress], "City is already registered");

        payFee(cityAddress, amount);

        registeredCities[cityAddress] = true;

        City storage newCity = cityStore[cityAddress];
        newCity.name = cityName;
        newCity.location = string(abi.encodePacked("Lat: ", lat, ", Lng: ", lng));
        newCity.longitude = lng;
        newCity.latitude = lat;
        newCity.carbonCapacity = carbonCapacity;
        newCity.amountPaid = amount;
        newCity.cityCountId = totalSupply(); // Assign an ID based on total supply

        _mint(cityAddress, amount); // Mint tokens to the registered city
    }

    function getCityParameters(
        address cityAddress,
        uint256 carbonEmission,
        uint256 temp,
        uint256 humidity
    ) external onlyOwner {
        uint256 timeOfDay = block.timestamp;

        // Store city parameters
        cityStore[cityAddress].carbonCapacity = carbonEmission;
        cityStore[cityAddress].longitude = temp;
        cityStore[cityAddress].latitude = humidity;
        carbonLevels[cityAddress] = carbonEmission;

        emit GetCityParams(cityAddress, carbonEmission, temp, humidity, timeOfDay);
    }

    event GetCityParams(
        address indexed cityAddress,
        uint256 carbonEmission,
        uint256 temp,
        uint256 humidity,
        uint256 timeOfDay
    );

    function setMaximumCarbonLevel(address cityAddress, uint256 maximumCarbonLevel) external returns (address, uint256) {
        // Check if the carbon level for the city is not set (initialized to 0)
        if (carbonLevels[cityAddress] == 0) {
            maxCreditLevels[cityAddress] = maximumCarbonLevel;
        }

        return (cityAddress, maximumCarbonLevel);
    }

    function getCarbonLevel(address cityAddress) external view returns (uint256) {
        return carbonLevels[cityAddress];
    }

    function getCarbonCredit(address cityAddress) external view returns (uint256) {
        uint256 carbonCredit = maxCreditLevels[cityAddress] - carbonLevels[cityAddress];
        carboncredit[cityAddress] = carbonCredit; 
        return carbonCredit;
    }
}
