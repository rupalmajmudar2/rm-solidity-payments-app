pragma solidity ^0.4.20;
pragma experimental ABIEncoderV2;
    
library SharedStructs {
    struct Service {
        string name;
        uint256 price;
    }   
}

//@courtesy https://programtheblockchain.com/posts/2017/12/15/writing-a-contract-that-handles-ether/
contract PaymentFunctions {
    event LogMoneyTransfer(address sender, address receiver, uint256 amount);
        
    function withdrawAll() public {
        msg.sender.transfer(address(this).balance);
    }

    /*
     * address.transfer(amount) transfers amount (in ether) 
     * _TO_ the account represented by address.
     */
    function withdraw(uint256 amount) payable public {
        msg.sender.transfer(amount);
        emit LogMoneyTransfer(address(this), msg.sender, amount);
    }
    
    function withdrawalByAddress(uint256 amount, address addr) payable public {
        addr.transfer(amount);
        emit LogMoneyTransfer(address(this), addr, amount);
    }
    
    //@see faq: https://stackoverflow.com/questions/52003763/even-though-i-dont-have-constructor-in-my-code-i-am-getting-error-the-construct
    function deposit(uint256 amount) payable public {
        //require(msg.value == amount); TODO: CHK!
        // nothing else to do!
        emit LogMoneyTransfer(msg.sender, address(this), amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getBalance(address addr) public view returns (uint256) {
        return addr.balance;
    }
}

contract Provider {
    
    //using SService for SharedStructs.Service; Later.
    
    string providerName;
    address providerAddress;
        
    SharedStructs.Service[] services;
    mapping(string => SharedStructs.Service) serviceByName;
    mapping(string => bool) servicesExisting;
        
    /**
     * TODO: We use this constructor for creating a Provider for a Payment.
     * But should not need to enter this info when deploying the Provider, right??
     **/
    constructor (address _providerAddress, string _providerName) public {
        providerAddress= _providerAddress;
        providerName = _providerName;
        //services = new Service[](0); //not reqd
    }
    
    function getName() public view returns (string) {
        return providerName;
    }
    
    function getAddress() public view returns (address) {
        return providerAddress;
    }
    
    function offerService(string serviceName, uint256 servicePrice) public {
        if (servicesExisting[serviceName]) return;
        
        // add service to the list of services of the given provider
        SharedStructs.Service memory srv= SharedStructs.Service(serviceName, servicePrice);
        services.push(srv);
        serviceByName[serviceName] = srv;
        servicesExisting[serviceName] = true;
    }
    
    function getServices() public view returns (SharedStructs.Service[]) {
        return services;
    }
    
    function doesServiceExist(string serviceName) public view returns (bool) {
        bool exists= servicesExisting[serviceName];
        return exists;
    }
    
    function getService(string serviceName) public view returns (SharedStructs.Service) {
        SharedStructs.Service storage srv= serviceByName[serviceName];
        return srv;
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
    function addProvider(string _provName) public {
        if (providersExistingByName[_provName]) return;
        
        Provider newProvider = new Provider(msg.sender, _provName);
        address msg_sender= msg.sender; //for debugging. Strange 0's get prefixed!
        providersArray.push(newProvider);
        providersByName[_provName]= newProvider;
        providersByAddress[msg_sender]= newProvider; //unique name & address for each provider. Fair enough?
        providersExistingByAddress[msg_sender] = true;
        providersExistingByName[_provName]= true;
    }
  
    function getProviders() public view returns (Provider[]) { 
        return providersArray;
    }
    
    //@TODO: Review. @see https://ethereum.stackexchange.com/questions/30665/warning-uninitialized-storage-pointer
    //@TODO: Also dunno how to get rid of "Warning: Uninitialized storage pointer"
    function getAllProviderNames() public view returns (string[]) { 
        //uint256 len= providersArray.length + 1;
        //string[] storage names = new string[](len);
        string[] storage names;
        for (uint i=0; i<providersArray.length; i++) {
            names.push(providersArray[i].getName());
        }
        
        return names;
    }
    
    //======================================================
        
    function offerService(string providerName, string serviceName, uint256 servicePrice) public {
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
        bool exists = providersExistingByAddress[providerAddress];
        if (!exists) return;
        
        Provider provider = providersByAddress[providerAddress];
        if (!provider.doesServiceExist(serviceName)) return;
        
        SharedStructs.Service memory service= provider.getService(serviceName);
        uint256 serviceCost = service.price; 
                
        // make payment -> substract money from caller [address: msg.sender], 
        //send money to the provider [address: providerAddress]
        //amount: serviceCost
        PaymentFunctions pf= new PaymentFunctions();
        //TODO BUG - serviceCost value comes to be 0 !!
        pf.deposit(150); //Money from the user (msg.sender) to this contract.
        pf.withdrawalByAddress(150, providerAddress);
    }
}