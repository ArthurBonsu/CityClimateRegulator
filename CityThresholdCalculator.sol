// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CityThresholdCalculator {
    // Structs
    struct City {
        uint256 healthIndex;           // H_city
        uint256 regionId;
        bool isVulnerable;
        bool exists;
    }

    struct Region {
        uint256 maxHealthIndex;        // H_max
        uint256 thresholdValue;        // H_thresh
        uint256[] cityIds;
        bool exists;
    }

    // State variables
    mapping(uint256 => City) public cities;
    mapping(uint256 => Region) public regions;
    uint256 public thresholdPercentage;    // P_th (scaled by 1e18)
    address public gdcccAddress;           // GDCCC contract address

    // Events
    event CityHealthUpdated(uint256 indexed cityId, uint256 healthIndex);
    event RegionThresholdUpdated(uint256 indexed regionId, uint256 thresholdValue);
    event CityVulnerabilityChanged(uint256 indexed cityId, bool isVulnerable);
    event NewCityAdded(uint256 indexed cityId, uint256 indexed regionId);

    // Modifiers
    modifier onlyGDCCC() {
        require(msg.sender == gdcccAddress, "Only GDCCC can call this function");
        _;
    }

    modifier cityExists(uint256 cityId) {
        require(cities[cityId].exists, "City does not exist");
        _;
    }

    modifier regionExists(uint256 regionId) {
        require(regions[regionId].exists, "Region does not exist");
        _;
    }

    // Constructor
    constructor(address _gdcccAddress, uint256 _thresholdPercentage) {
        gdcccAddress = _gdcccAddress;
        thresholdPercentage = _thresholdPercentage;
    }

    // Function to add a new region
    function addRegion(uint256 regionId) external onlyGDCCC {
        require(!regions[regionId].exists, "Region already exists");
        
        regions[regionId].exists = true;
        regions[regionId].maxHealthIndex = 0;
        regions[regionId].thresholdValue = 0;
    }

    // Function to add a new city to a region
    function addCity(
        uint256 cityId, 
        uint256 regionId, 
        uint256 initialHealthIndex
    ) external onlyGDCCC regionExists(regionId) {
        require(!cities[cityId].exists, "City already exists");
        
        cities[cityId] = City({
            healthIndex: initialHealthIndex,
            regionId: regionId,
            isVulnerable: false,
            exists: true
        });

        regions[regionId].cityIds.push(cityId);
        updateRegionMaxHealth(regionId);
        
        emit NewCityAdded(cityId, regionId);
    }

    // Function to update city health index
    function updateCityHealth(
        uint256 cityId, 
        uint256 newHealthIndex
    ) external onlyGDCCC cityExists(cityId) {
        City storage city = cities[cityId];
        city.healthIndex = newHealthIndex;
        
        updateRegionMaxHealth(city.regionId);
        assessCityVulnerability(cityId);
        
        emit CityHealthUpdated(cityId, newHealthIndex);
    }

    // Function to update region's maximum health index
    function updateRegionMaxHealth(uint256 regionId) internal regionExists(regionId) {
        Region storage region = regions[regionId];
        uint256 maxHealth = 0;
        
        for (uint256 i = 0; i < region.cityIds.length; i++) {
            uint256 cityHealth = cities[region.cityIds[i]].healthIndex;
            if (cityHealth > maxHealth) {
                maxHealth = cityHealth;
            }
        }
        
        region.maxHealthIndex = maxHealth;
        updateRegionThreshold(regionId);
    }

    // Function to calculate and update region threshold
    function updateRegionThreshold(uint256 regionId) internal regionExists(regionId) {
        Region storage region = regions[regionId];
        
        // Calculate H_thresh = P_th * H_max
        uint256 newThreshold = (region.maxHealthIndex * thresholdPercentage) / 1e18;
        region.thresholdValue = newThreshold;
        
        // Reassess all cities in the region
        for (uint256 i = 0; i < region.cityIds.length; i++) {
            assessCityVulnerability(region.cityIds[i]);
        }
        
        emit RegionThresholdUpdated(regionId, newThreshold);
    }

    // Function to assess city vulnerability
    function assessCityVulnerability(uint256 cityId) internal cityExists(cityId) {
        City storage city = cities[cityId];
        Region storage region = regions[city.regionId];
        
        bool wasVulnerable = city.isVulnerable;
        city.isVulnerable = city.healthIndex > region.thresholdValue;
        
        if (wasVulnerable != city.isVulnerable) {
            emit CityVulnerabilityChanged(cityId, city.isVulnerable);
            if (city.isVulnerable) {
                // Trigger Carbon Regulating Contract
                notifyCarbonRegulator(cityId);
            }
        }
    }

    // Function to update threshold percentage
    function updateThresholdPercentage(uint256 newThresholdPercentage) external onlyGDCCC {
        thresholdPercentage = newThresholdPercentage;
        
        // Update all regions with new threshold
        // Note: In production, consider gas costs and potentially breaking this into multiple transactions
        uint256[] memory activeRegions = getActiveRegions();
        for (uint256 i = 0; i < activeRegions.length; i++) {
            updateRegionThreshold(activeRegions[i]);
        }
    }

    // Function to get all active regions
    function getActiveRegions() internal view returns (uint256[] memory) {
        // Implementation depends on how you want to track active regions
        // This is a placeholder - you'll need to implement region tracking
        return new uint256[](0);
    }

    // Function to notify Carbon Regulating Contract
    function notifyCarbonRegulator(uint256 cityId) internal {
        // Implementation depends on your Carbon Regulating Contract interface
        // This is a placeholder for the actual implementation
    }

    // View functions
    function getCityHealth(uint256 cityId) external view cityExists(cityId) returns (uint256) {
        return cities[cityId].healthIndex;
    }

    function getCityVulnerability(uint256 cityId) external view cityExists(cityId) returns (bool) {
        return cities[cityId].isVulnerable;
    }

    function getRegionThreshold(uint256 regionId) external view regionExists(regionId) returns (uint256) {
        return regions[regionId].thresholdValue;
    }

    function getRegionMaxHealth(uint256 regionId) external view regionExists(regionId) returns (uint256) {
        return regions[regionId].maxHealthIndex;
    }
}
