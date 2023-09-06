// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/CityRegister.sol";

contract CompanyRegister is CityRegister, ERC20, Ownable {
    address public _owner;
    string private _tokenName = "RPSTOKENS";
    string private _tokenSymbol = "RPS";
    uint256 private _payFee = 0;

    struct Company {
        address companyAddress;
        address city;
        string name;
        string location;
        uint256 longitude;
        uint256 latitude;
        uint256 carbonCapacity;
        uint256 amountPaid;
        uint256 companyCountId;
    }

    uint256 public totalSupplyTokens = 1000000;

    mapping(address => bool) public registeredCompanies;
    mapping(address => bool) public paidCompanyEscrowFee;
    mapping(address => mapping(address => bool)) public checkIfCompanyIsInCity;

    mapping(address => Company) public companyStore;
    mapping(address => mapping(uint256 => uint256)) public temperature;
    mapping(address => mapping(uint256 => uint256)) public carbonCapacityCompany;
    mapping(address => mapping(uint256 => uint256)) public humidity;


 /// checkimg carbon level of companiesw

 mapping(address => uint256) public companycarbonLevels;
    mapping(address => uint256) public companymaxCreditLevels;
      mapping(address => uint256) public companycarboncredit;

    Company[] public newCompany;

    event GetCompanyParams(
        address indexed city,
        address indexed companyAddress,
        uint256 carbonEmission,
        uint256 temperature,
        uint256 humidity,
        uint256 timeOfDay
    );

    constructor(address ownerAddress) ERC20(_tokenName, _tokenSymbol) {
        _owner = ownerAddress;
        totalSupply();
    }

    function payFees(address payable sender, address payable ownerAddress, uint256 amount) external payable {
        _owner = ownerAddress;
        _payFee = amount;
        require(amount >= 10 ether, "Amount must be at least 10 ether");

        (bool success, ) = _owner.call{value: _payFee}("");
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

        payFees(companyAddress, _owner, amount);

        if (!checkIfCompanyIsInCity[cityAddress][companyAddress]) {
            if (paidCompanyEscrowFee[companyAddress]) {
                if (!registeredCompanies[companyAddress]) {
                    registeredCompanies[companyAddress] = true;

                    uint256 myLocation = getLocation(lng, lat);

                    companyStore[companyAddress] = Company({
                        companyAddress: companyAddress,
                        city: cityAddress,
                        name: companyName,
                        location: myLocation,
                        longitude: lng,
                        latitude: lat,
                        carbonCapacity: carbonCapacity,
                        amountPaid: amount,
                        companyCountId: companyCount
                    });

                    checkIfCompanyIsInCity[cityAddress][companyAddress] = true;

                    newCompany.push(companyStore[companyAddress]);
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
        return string(abi.encodePacked("Lat: ", lat, ", Lng: ", lng));
    }

    function getCompanyParameters(
        address city,
        address companyAddress,
        uint256 carbonEmission,
        uint256 temp,
        uint256 humidity
    ) external onlyOwner returns (address, uint256, uint256, uint256, uint256) {
        uint256 timeOfDay = block.timestamp;

        temperature[companyAddress][timeOfDay] = temp;
        carbonCapacityCompany[companyAddress][timeOfDay] = carbonEmission;
        humidity[companyAddress][timeOfDay] = humidity;

        emit GetCompanyParams(city, companyAddress, carbonEmission, temp, humidity, timeOfDay);

        return (city, companyAddress, carbonEmission, temp, humidity);
    }

}
