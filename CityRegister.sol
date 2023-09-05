
pragma solidity 0.8.2;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import './StringUtils.sol';




// Company to Company Setup 

// City Register 
//Company Register{name, address, nre device numbers, date of creation, company size, fuel}

// Fuel emission per day 
// carbon emission per day from fuel
// nre emmission per day 
// nre carbon emmission 
// Company fuel = nre carbon + carbon emission per day

// transfer fee tokens

// Company Vault Parameter s


// Company Register
// 
//Carbon Monitoring  Contract

// City Carbon Details 
// Calculate city temperature 
// set city status 

// Carbon Regulating Contract
// compare parameters 

 //a) if temperature, humidity, wind, pressure < threshold  , 
 //b) increase parameters 
 

// Carbon Trading Contract 
// a) Uniswap , Swap, Vault,Pair Token 
// Token submit
  // @dev contract for rock,paper game0
contract CityRegister is    Ownable,ERC20 {
    
    

    address public _owner;
   
         
  
       struct City  {
             address  cityadderess;
             string name;
             string location;
             uint256 longitude;
             uint256 latitude;
             uint256 carboncapacity;
             uint256 amountpaid; 
             uint256 citycountid;
             
             }

  
    uint256 public totalsupplytokens = 1000000;
    mapping(address => address) registeredcities;
    mapping(address => uint256) balances;

    mapping(address=>City)public _citystore;
   mapping(address => bool) registeredornot;
     mapping(address => bool) paidcityescrowfee;
      mapping(address => mapping(uint256 => uint256)) temperature;
      mapping(address => mapping(uint256 => uint256)) carboncapacity;
    mapping(address => mapping(uint256 => uint256)) humidity;
  
  // @dev objects inheriting from previous structs
   City  newcity;   
    City[] public newgamecity;
      
    
      
      constructor(address __owner) ERC20(_tokenname, _tokensymbol ) {
        _owner =__owner;
        
         totalSupply();
         

    }

  

  // @dev fees to be paid to be registered for game 
  // @params player=sender, contractowner,ether amount to be sent 
   event  getCityParams(address cityaddress, uint256 carbonemmission, uint256 temperature, uint256 humidity,uint256 timeoftheday) ;
  
function payfee(address payable sender, address payable owneraddress, uint256 amount) public payable returns(bool, bytes memory){
        
         _owner =owneraddress;
        _payfee = amount;
     
        require ( amount >= 10, "Amount not enough to play!");
    
          (bool success,bytes memory data ) = _owner.call{value: _payfee}("");
            require(success, "Check the amount sent as well"); 
             paidcityescrowfee[sender]= true;
    return (success,data);
    }

   // @dev registeration for game  
  // @params players name and address
  
    function registerCity(string memory _cityname, address payable _cityaddress, uint256 _amount, uint256 _lng, uint256 _lat, uint256 _carboncapacity) public  returns(string memory, address){
         // this means whoever is the owner is now the 
         uint256 citycount = 0;
              require(msg.sender == _owner , "Caller is not owner");
              
              payfee(_cityaddress, _owner,  _amount);
         
               if (paidcityescrowfee[_cityaddress] == true){
            uint256 citybalance =0;
            citybalance = balanceOf(_cityaddress);

           if(registeredcities[_cityaddress] != _cityaddress){
           
            registeredcities[_cityaddress] =_cityaddress ;
     uint256 mylocation = getLocation(_lng, _lat);
         
            // @dev storing to memory
            newcity = City(_cityaddress,_cityname,location, _lng, _lat,  _carboncapacity, _amount,citycountid ); 
             _citystore[_cityaddress].cityadderess = _cityaddress;
             _citystore[_cityaddress].name = _cityname;
             _citystore[_cityaddress].location = mylocation;
             _citystore[_cityaddress].longitude = _lng;
            _citystore[_cityaddress].latitude = _lat;
            _citystore[_cityaddress].carboncapacity = carboncapacity;
             _citystore[_cityaddress].amountpaid = _amount;
             _citystore[_cityaddress].citycountid = citycount;
                 // @dev storing to storage  -optional
  
  
            newgamecity.push(newcity);                        

            return (_cityaddress,_cityname,location, _lng, _lat,  _carboncapacity, _amount,citycountid  );
     
}
}
    }


 function getLatitude (uint256 _lat ) external  returns (uint finallat){
   return  (_lat);
 }

 function getLongitude (uint256 _lng ) external  returns (uint finallng){
 return (_lng) ;
 }

 function getLocation (uint256 _lat, uint256 lng) external  returns (uint256 _lat,uint256 _lng   ){
   return (_lat, _lng) ;
 }



function getCityParameters (address cityaddress, uint256 carbonemmission, uint256 temperature, uint256 humidity) external returns (uint256 _carbonemmission, uint256 _temperature, uint256 _humidity, uint256 _timeoftheday) {
     uint256 timeoftheday = block.timestamp; 

     temperature[cityaddress][timeoftheday] =temperature;
     carboncapacity[cityaddress][timeoftheday] = carbonemmission;
    carboncapacity[cityaddress][timeoftheday] = humidity;
     
 emit getCityParams( cityaddress, carbonemmission,  temperature, humidity, timeoftheday) ;
     
  return (carbonemmission,  temperature,  humidity,timeoftheday);
}
        

 }
    
      // @dev register game, game id as random generator integer
