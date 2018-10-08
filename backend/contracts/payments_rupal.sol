pragma solidity ^0.4.20;
pragma experimental ABIEncoderV2;
    
library SharedStructs {
    struct Service {
        string name;
        uint8 price;
    }   
}

contract Provider {
    
    //using SService for SharedStructs.Service; Later.
    
    string providerName;
    address providerAddress;
        
    SharedStructs.Service[] services;
    mapping(string => bool) servicesExisting;
        
    constructor (address _providerAddress, string _providerName) public payable {
        providerAddress = _providerAddress;
        providerName = _providerName;
        //services = new Service[](0); //not reqd
    }
    
    function getName() public returns (string) {
        return providerName;
    }
    
    function getAddress() public returns (address) {
        return providerAddress;
    }
    
    function offerService(string serviceName, uint8 servicePrice) public {
        if (servicesExisting[serviceName]) return;
        
        // add service to the list of services of the given provider
        SharedStructs.Service memory srv= SharedStructs.Service(serviceName, servicePrice);
        services.push(srv);
        servicesExisting[serviceName] = true;
    }
    
    function getServices() public returns (SharedStructs.Service[]) {
        return services;
    }
    
    function doesServiceExist(string serviceName) public returns (bool) {
        return servicesExisting[serviceName];
    }
}

contract Payments {
    mapping(address => bool) private users;
    address[] private usersArray;

    mapping(string => bool) providersExistingByName;    
    mapping(string => Provider) providersByName;
    mapping(address => bool) providersExistingByAddress;
    mapping(address => Provider) providersByAddress;
    Provider[] providersArray;
    
    function addUser(address _user) public {
        if (users[_user]) return;
        
        usersArray.push(_user);
        users[_user]= true;
    }
    
    function addUser() public {
        if (users[msg.sender]) return;
        
        usersArray.push(msg.sender);
        users[msg.sender]= true;
    }
    
    function getUsers() public view returns (address[]) {
        return usersArray;
    }
    
    //======================================================
    
    //From https://medium.com/loom-network/ethereum-solidity-memory-vs-storage-how-to-initialize-an-array-inside-a-struct-184baf6aa2eb
    function addProvider(string _provName) public payable {
        if (providersExistingByName[_provName]) return;
        
        Provider newProvider = new Provider(msg.sender, _provName);
        
        providersArray.push(newProvider);
        providersByName[_provName]= newProvider;
        providersByAddress[msg.sender]= newProvider; //unique name & address for each provider. Fair enough?
        providersExistingByName[_provName]= true;
    }
  
    function getProviders() public view returns (Provider[]) { 
        return providersArray;
    }
    
    function getAllProviderNames() public view returns (string[]) { 
        string[] names;
        for (uint i=0; i<providersArray.length; i++) {
            names.push(providersArray[i].getName());
        }
        
        return names;
    }
    
    //======================================================
        
    function offerService(string providerName, string serviceName, uint8 servicePrice) public {
        if (!providersExistingByName[providerName]) return;
        
        Provider provider= providersByName[providerName];
        if (provider.getAddress() != msg.sender) return;
        
        provider.offerService(serviceName, servicePrice);
    }
    
    function getOffers(address providerAddr) public view returns (SharedStructs.Service[]) {
        if (!providersExistingByAddress[providerAddr]) return; 
        
        Provider prov= providersByAddress[providerAddr];
        return prov.getServices();        
    }
    
    function getOffers(string providerName) public view returns (SharedStructs.Service[]) {
        if (!providersExistingByName[providerName]) return;
        
        Provider provider= providersByName[providerName];
        return provider.getServices(); 
    }
    
    function makePayment(address providerAddress, string serviceName) public payable {
        if (!users[msg.sender]) return;
        if (!providersExistingByAddress[providerAddress]) return;
        
        Provider provider= providersByAddress[providerAddress];
        //SharedStructs.Service[] memory services= provider.getServices();
        if (!provider.doesServiceExist(serviceName)) return;
        
        // make payment -> substract money from caller, send money to the provider
        //
    }
}