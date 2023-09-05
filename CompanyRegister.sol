
pragma solidity 0.8.2;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import './StringUtils.sol';




// Company to Company Setup 

// company Register 
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

// company Carbon Details 
// Calculate company temperature 
// set company status 

// Carbon Regulating Contract
// compare parameters 

 //a) if temperature, humidity, wind, pressure < threshold  , 
 //b) increase parameters 
 

// Carbon Trading Contract 
// a) Uniswap , Swap, Vault,Pair Token 
// Token submit
  // @dev contract for rock,paper game0
contract CompanyRegister is    Ownable,ERC20 {
    
    

    address public _owner;
   
         
  
       struct Company  {
             address  companyadderess;
             address city; 
             string name;
             string location;
             uint256 longitude;
             uint256 latitude;
             uint256 _carboncapacity;
             uint256 amountpaid; 
             uint256 companycountid;
             
             }

  
    uint256 public totalsupplytokens = 1000000;
    mapping(address => address) registeredcompanies;
    mapping(address => uint256) balances;

    mapping(address=>company)public _companystore;
   mapping(address => bool) registeredornot;
     mapping(address => bool) paidcompanyescrowfee;

     mapping(address => mapping(address => address)) companyincity;
         mapping(address => mapping(address => bool)) checkifcompanyisincity;
      mapping(address => mapping(uint256 => uint256)) temperature;
      mapping(address => mapping(uint256 => uint256)) carboncapacity;
    mapping(address => mapping(uint256 => uint256)) humidity;
  
  // @dev objects inheriting from previous structs
   company  newcompany;   
    company[] public newgamecompany;
      
    
      
      constructor(address __owner) ERC20(_tokenname, _tokensymbol ) {
        _owner =__owner;
        
         totalSupply();
         

    }

  

  // @dev fees to be paid to be registered for game 
  // @params player=sender, contractowner,ether amount to be sent 
   event  getcompanyParams(address city, address companyaddress, uint256 carbonemmission, uint256 temperature, uint256 humidity,uint256 timeoftheday) ;
  
function payfee(address payable sender, address payable owneraddress, uint256 amount) public payable returns(bool, bytes memory){
        
         _owner =owneraddress;
        _payfee = amount;
     
        require ( amount >= 10, "Amount not enough to play!");
    
          (bool success,bytes memory data ) = _owner.call{value: _payfee}("");
            require(success, "Check the amount sent as well"); 
             paidcompanyescrowfee[sender]= true;
    return (success,data);
    }

   // @dev registeration for game  
  // @params players name and address
  
    function registercompany(string memory _companyname, address payable _companyaddress,address _cityaddress,  uint256 _amount, uint256 _lng, uint256 _lat, uint256 _carboncapacity) public  returns(address __companyaddress,address _cityaddress, string _companyname,uint256 location, uint256 _lng, uint256 _lat,  uint256 _carboncapacity,uint256 _amount,uint256 companycountid ){
         // this means whoever is the owner is now the 
         uint256 companycount = 0;
              require(msg.sender == _owner , "Caller is not owner");
              
              payfee(_companyaddress, _owner,  _amount);
                   if(checkifcompanyisincity[_cityaddress][_companyaddress] = false) {
               if (paidcompanyescrowfee[_companyaddress] == true){
            uint256 companybalance =0;
            companybalance = balanceOf(_companyaddress);

           if(registeredcompanies[_companyaddress] != _companyaddress){
           
            registeredcompanies[_companyaddress] =_companyaddress ;
     uint256 mylocation = getLocation(_lng, _lat);

           companyincity[_cityaddress][_companyaddress] =_companyaddress;
           checkifcompanyisincity[_cityaddress][_companyaddress] = true;
            // @dev storing to memory
            newcompany = company(_companyaddress,_cityaddress, _companyname,location, _lng, _lat,  _carboncapacity, _amount,companycountid ); 
             _companystore[_companyaddress].companyadderess = _companyaddress;
               _companystore[_companyaddress].city = _cityaddress;
             _companystore[_companyaddress].name = _companyname;
             _companystore[_companyaddress].location = mylocation;
             _companystore[_companyaddress].longitude = _lng;
            _companystore[_companyaddress].latitude = _lat;
            _companystore[_companyaddress].carboncapacity = carboncapacity;
             _companystore[_companyaddress].amountpaid = _amount;
             _companystore[_companyaddress].companycountid = companycount;
                 // @dev storing to storage  -optional
  
  
            newgamecompany.push(newcompany);                        
           }
            return (__companyaddress, _cityaddress,  _companyname, location,  _lng, _lat,  _carboncapacity, _amount, companycountid  );
     
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



function getcompanyParameters (address city, address companyaddress, uint256 carbonemmission, uint256 temperature, uint256 humidity) external returns (address city, uint256 _carbonemmission, uint256 _temperature, uint256 _humidity, uint256 _timeoftheday) {
     uint256 timeoftheday = block.timestamp; 

     temperature[companyaddress][timeoftheday] =temperature;
     carboncapacompany[companyaddress][timeoftheday] = carbonemmission;
    carboncapacompany[companyaddress][timeoftheday] = humidity;
     
 emit getcompanyParams(city,  companyaddress, carbonemmission,  temperature, humidity, timeoftheday) ;
     
  return (city, companyaddress, carbonemmission,  temperature,  humidity,timeoftheday);
}
        

 }
    
      // @dev register game, game id as random generator integer
   

