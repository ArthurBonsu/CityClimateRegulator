// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/CityRegister.sol";

contract CompanyRegister is Ownable, CityRegister {
    
    string private _tokenName = "RPSTOKENS";
    string private _tokenSymbol = "RPS";

    struct Company {
        address payable companyAddress;
        address city;
        string name;
        string location;
        uint256 longitude;
        uint256 latitude;
        uint256 carbonCapacity;
        uint256 amountPaid;
    }

    mapping(address => bool) public registeredCompanies;
    mapping(address => bool) public paidCompanyEscrowFee;
    mapping(address => mapping(address => bool)) public checkIfCompanyIsInCity;

    mapping(address => Company) public companyStore;
    mapping(address => mapping(uint256 => uint256)) public temperature;
    mapping(address => mapping(uint256 => uint256)) public carbonCapacityCompany;
    mapping(address => mapping(uint256 => uint256)) public humidity;

    mapping(address => uint256) public companycarbonLevels;
    mapping(address => uint256) public companymaxCreditLevels;
    mapping(address => uint256) public companycarboncredit;

    constructor(address __owner) CityRegister(__owner) {
        // Initialize state variables if needed
    }

    function payFees(address payable sender, uint256 amount) public payable {
        require(amount >= 10 ether, "Amount must be at least 10 ether");
        (bool success, ) = sender.call{value: amount}("");
        require(success, "Payment failed");
        paidCompanyEscrowFee[sender] = true;
    }

    function registerCompany(
        string memory companyName,
        address payable companyAddress,
        address cityAddress,
        uint256 amount,
        uint256 lng,
        uint256 lat,
        uint256 carbonCapacity
    ) external onlyOwner returns (address, string memory, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 companyCount = 0;
        require(msg.sender == _owner, "Caller is not the owner");

        payFees(companyAddress, amount);

       if (!checkIfCompanyIsInCity[cityAddress][companyAddress]) {
            if (paidCompanyEscrowFee[companyAddress]) {
                if (!registeredCompanies[companyAddress]) {
                    registeredCompanies[companyAddress] = true;

                    string memory myLocation = getLocation(lng, lat);

                    companyStore[companyAddress] = Company({
                        companyAddress: companyAddress,
                        city: cityAddress,
                        name: companyName,
                        location: myLocation,
                        longitude: lng,
                        latitude: lat,
                        carbonCapacity: carbonCapacity,
                        amountPaid: amount
                    });

                    checkIfCompanyIsInCity[cityAddress][companyAddress] = true;
                 }
           
            }
     
        }

        return (
            companyAddress,
            companyName,
            amount,
            lng,
            lat,
            carbonCapacity,
            amount,
            companyCount
        );
    
    }

    function getLatitude(uint256 lat) external pure returns (uint256) {
        return lat;
    }

    function getLongitude(uint256 lng) external pure returns (uint256) {
        return lng;
    }

    function getLocation(uint256 lat, uint256 lng) internal pure returns (string memory) {
        return string(abi.encodePacked("Lat: ", uintToStr(lat), ", Lng: ", uintToStr(lng)));
    }

    function uintToStr(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function setMaximumCompanyCarbonLevel(address cityAddress, uint256 maximumCarbonLevel) external returns (address, uint256) {
        // Check if the carbon level for the city is not set (initialized to 0)
        if (companycarbonLevels[cityAddress] == 0) {
            companymaxCreditLevels[cityAddress] = maximumCarbonLevel;
        }

        return (cityAddress, maximumCarbonLevel);
    }

    function getCompanyCarbonLevel(address cityAddress) external view returns (uint256) {
        return companycarbonLevels[cityAddress];
    }

    function getCompanyCarbonCredit(address cityAddress) external returns (uint256) {
        uint256 companycarboncredits = companymaxCreditLevels[cityAddress] - companycarbonLevels[cityAddress];
        companycarboncredit[cityAddress];
    }
    
    }
