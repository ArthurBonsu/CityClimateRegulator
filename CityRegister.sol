// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CityRegister is ERC20, Ownable {
    using SafeMath for uint256;

    // Struct to store daily measurement
    struct DailyMeasurement {
        uint256 timestamp;
        uint256 value;     // Stored as value * 1e18 for precision
        bool recorded;
    }

    // Struct to store sector data
    struct SectorData {
        mapping(uint256 => DailyMeasurement) dailyData;  // timestamp => measurement
        uint256[] recordedDates;
        uint256 baselineValue;
        uint256 rollingAverage;    // Stored as value * 1e18
        uint256 maxHistoricalValue;
        bool isActive;
    }

    struct City {
        string name;
        bool isRegistered;
        mapping(string => SectorData) sectors;
        string[] activeSectors;
        uint256 registrationDate;
    }

    mapping(string => City) public cities;
    string[] public registeredCityNames;

    // Events
    event CityRegistered(string cityName, uint256 timestamp);
    event SectorAdded(string cityName, string sectorName, uint256 timestamp);
    event DailyDataRecorded(
        string indexed cityName,
        string indexed sector,
        uint256 timestamp,
        uint256 value
    );

    constructor() ERC20("RPSTOKENS", "RPS") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function registerCity(string memory cityName) external onlyOwner {
        require(bytes(cityName).length > 0, "City name cannot be empty");
        require(!cities[cityName].isRegistered, "City already registered");

        City storage newCity = cities[cityName];
        newCity.name = cityName;
        newCity.isRegistered = true;
        newCity.registrationDate = block.timestamp;

        registeredCityNames.push(cityName);
        
        emit CityRegistered(cityName, block.timestamp);
    }

    function addSector(string memory cityName, string memory sectorName) external onlyOwner {
        require(cities[cityName].isRegistered, "City not registered");
        require(!cities[cityName].sectors[sectorName].isActive, "Sector already exists");

        City storage city = cities[cityName];
        SectorData storage newSector = city.sectors[sectorName];
        newSector.isActive = true;
        city.activeSectors.push(sectorName);

        emit SectorAdded(cityName, sectorName, block.timestamp);
    }

    function recordDailyValue(
        string memory cityName,
        string memory sectorName,
        uint256 timestamp,
        uint256 value
    ) external onlyOwner {
        require(cities[cityName].isRegistered, "City not registered");
        require(cities[cityName].sectors[sectorName].isActive, "Sector not active");

        // Convert the small decimal to a larger integer by multiplying by 1e18
        uint256 scaledValue = value * 1e18;
        
        SectorData storage sector = cities[cityName].sectors[sectorName];
        
        // Store the daily measurement
        DailyMeasurement storage measurement = sector.dailyData[timestamp];
        require(!measurement.recorded, "Data already recorded for this date");
        
        measurement.timestamp = timestamp;
        measurement.value = scaledValue;
        measurement.recorded = true;
        sector.recordedDates.push(timestamp);

        // Update maximum historical value if necessary
        if (scaledValue > sector.maxHistoricalValue) {
            sector.maxHistoricalValue = scaledValue;
        }

        // Update rolling average
        uint256 daysToAverage = 7; // Weekly rolling average
        uint256 totalValues = 0;
        uint256 count = 0;
        
        for (uint256 i = sector.recordedDates.length; i > 0 && count < daysToAverage; i--) {
            totalValues = totalValues.add(sector.dailyData[sector.recordedDates[i-1]].value);
            count++;
        }
        
        if (count > 0) {
            sector.rollingAverage = totalValues.div(count);
        }

        emit DailyDataRecorded(cityName, sectorName, timestamp, scaledValue);
    }

    function getDailyValue(
        string memory cityName,
        string memory sectorName,
        uint256 timestamp
    ) external view returns (uint256 value, bool recorded) {
        require(cities[cityName].isRegistered, "City not registered");
        require(cities[cityName].sectors[sectorName].isActive, "Sector not active");

        DailyMeasurement storage measurement = cities[cityName].sectors[sectorName].dailyData[timestamp];
        return (measurement.value, measurement.recorded);
    }

    function getSectorStats(
        string memory cityName,
        string memory sectorName
    ) external view returns (
        uint256 totalRecordings,
        uint256 maxValue,
        uint256 rollingAverage
    ) {
        require(cities[cityName].isRegistered, "City not registered");
        require(cities[cityName].sectors[sectorName].isActive, "Sector not active");

        SectorData storage sector = cities[cityName].sectors[sectorName];
        return (
            sector.recordedDates.length,
            sector.maxHistoricalValue,
            sector.rollingAverage
        );
    }

    function getActiveSectors(string memory cityName) 
        external 
        view 
        returns (string[] memory) 
    {
        require(cities[cityName].isRegistered, "City not registered");
        return cities[cityName].activeSectors;
    }

    function calculateCarbonCredit(
        string memory cityName,
        string memory sectorName,
        uint256 timestamp
    ) external view returns (uint256) {
        require(cities[cityName].isRegistered, "City not registered");
        require(cities[cityName].sectors[sectorName].isActive, "Sector not active");

        SectorData storage sector = cities[cityName].sectors[sectorName];
        DailyMeasurement storage measurement = sector.dailyData[timestamp];
        require(measurement.recorded, "No data recorded for this date");

        if (measurement.value >= sector.maxHistoricalValue) {
            return 0;
        }

        return sector.maxHistoricalValue.sub(measurement.value);
    }
}
