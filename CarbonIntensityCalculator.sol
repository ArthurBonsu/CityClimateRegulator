// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarbonIntensityCalculator {
    // Structs to store emissions data
    struct IndustryEmissions {
        uint256 nreEmissions;      // E_NRE
        uint256 indEmissions;      // E_ind
        uint256 genEmissions;      // E_gen
        uint256 storageEmissions;  // E_storage
        uint256 fuelEmissions;     // c_fuel
        uint256 distEmissions;     // c_dist
        uint256 deltaFactor;       // δ
    }

    struct CityData {
        uint256 totalEmissions;    // TMTCO2e
        uint256 industryCount;     // nCM
        mapping(uint256 => IndustryEmissions) industries;
    }

    // State variables
    mapping(uint256 => CityData) public cities;
    mapping(string => uint256) public fuelCarbonContent; // Φ

    // Events
    event EmissionsCalculated(uint256 indexed cityId, uint256 totalEmissions);
    event FuelEmissionsCalculated(uint256 indexed cityId, uint256 indexed industryId, uint256 emissions);

    constructor() {
        // Initialize fuel carbon content constants
        // Values are multiplied by 1e18 for fixed-point arithmetic
        fuelCarbonContent["coal"] = 2.42e18;   // Example value: 2.42 MT CO2e/MT fuel
        fuelCarbonContent["gas"] = 2.75e18;    // Example value: 2.75 MT CO2e/MT fuel
        fuelCarbonContent["oil"] = 3.15e18;    // Example value: 3.15 MT CO2e/MT fuel
    }

    // Calculate fuel emissions (Fe = FCmeasured * Φ)
    function calculateFuelEmissions(
        uint256 fuelConsumption,
        string memory fuelType
    ) public view returns (uint256) {
        require(fuelCarbonContent[fuelType] > 0, "Invalid fuel type");
        return (fuelConsumption * fuelCarbonContent[fuelType]) / 1e18;
    }

    // Calculate distribution emissions (Edist)
    function calculateDistributionEmissions(
        uint256 nreEmissions,
        uint256 indEmissions,
        uint256 genEmissions,
        uint256 storageEmissions
    ) public pure returns (uint256) {
        return nreEmissions + indEmissions + genEmissions + storageEmissions;
    }

    // Calculate production emissions (Eprod)
    function calculateProductionEmissions(
        uint256 fuelEmissions,
        uint256 distEmissions,
        uint256 deltaFactor
    ) public pure returns (uint256) {
        return (fuelEmissions + distEmissions) * deltaFactor;
    }

    // Record industry emissions data
    function recordIndustryEmissions(
        uint256 cityId,
        uint256 industryId,
        uint256 nreEmissions,
        uint256 indEmissions,
        uint256 genEmissions,
        uint256 storageEmissions,
        uint256 fuelEmissions,
        uint256 deltaFactor
    ) public {
        IndustryEmissions storage industry = cities[cityId].industries[industryId];
        
        industry.nreEmissions = nreEmissions;
        industry.indEmissions = indEmissions;
        industry.genEmissions = genEmissions;
        industry.storageEmissions = storageEmissions;
        industry.fuelEmissions = fuelEmissions;
        industry.distEmissions = calculateDistributionEmissions(
            nreEmissions,
            indEmissions,
            genEmissions,
            storageEmissions
        );
        industry.deltaFactor = deltaFactor;

        // Update total emissions for the city
        updateCityEmissions(cityId);
    }

    // Update city's total emissions
    function updateCityEmissions(uint256 cityId) internal {
        uint256 totalEmissions = 0;
        CityData storage city = cities[cityId];

        for (uint256 i = 0; i < city.industryCount; i++) {
            IndustryEmissions storage industry = city.industries[i];
            uint256 industryEmissions = calculateProductionEmissions(
                industry.fuelEmissions,
                industry.distEmissions,
                industry.deltaFactor
            );
            totalEmissions += industryEmissions;
        }

        city.totalEmissions = totalEmissions;
        emit EmissionsCalculated(cityId, totalEmissions);
    }

    // Calculate carbon intensity per city (TMTCO2e/CMi)
    function calculateCityIntensity(uint256 cityId) public view returns (uint256) {
        CityData storage city = cities[cityId];
        require(city.industryCount > 0, "No industries recorded for city");
        return city.totalEmissions / city.industryCount;
    }

    // Add a new industry to a city
    function addIndustry(uint256 cityId) public {
        cities[cityId].industryCount++;
    }

    // Get industry emissions data
    function getIndustryEmissions(
        uint256 cityId,
        uint256 industryId
    ) public view returns (
        uint256 nreEmissions,
        uint256 indEmissions,
        uint256 genEmissions,
        uint256 storageEmissions,
        uint256 fuelEmissions,
        uint256 distEmissions,
        uint256 deltaFactor
    ) {
        IndustryEmissions storage industry = cities[cityId].industries[industryId];
        return (
            industry.nreEmissions,
            industry.indEmissions,
            industry.genEmissions,
            industry.storageEmissions,
            industry.fuelEmissions,
            industry.distEmissions,
            industry.deltaFactor
        );
    }
}
