pragma solidity ^0.4.20;
pragma experimental ABIEncoderV2;
    
library SharedStructs {
    struct Service {
        string name;
        uint256 price;
    }   
}

//@courtesy https://programtheblockchain.com/posts/2017/12/15/writing-a-contract-that-handles-ether/
/*contract PaymentFunctions {
    event LogMoneyTransfer(address sender, address receiver, uint256 amount);
        
    constructor() public payable {
        
    }
    
    function withdrawAll() public {
        msg.sender.transfer(address(this).balance);
    }

    //
    // address.transfer(amount) transfers amount (in ether) 
    // _TO_ the sender
    //
    function withdraw(uint256 amount) payable public {
        msg.sender.transfer(amount);
        //emit LogMoneyTransfer(address(this), msg.sender, amount);
    }
    
    
     // address.transfer(amount) transfers amount (in ether) 
     // _TO_ the account represented by address.
     //
    function withdrawalByAddress(uint256 amount, address addr) payable public {
        addr.transfer(amount);
        //emit LogMoneyTransfer(address(this), addr, amount);
    }
    
    //@see faq: https://stackoverflow.com/questions/52003763/even-though-i-dont-have-constructor-in-my-code-i-am-getting-error-the-construct
    function deposit(uint256 amount) payable public {
        //require(msg.value == amount); TODO: CHK!
        // nothing else to do!
        //emit LogMoneyTransfer(msg.sender, address(this), amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getBalance(address addr) public view returns (uint256) {
        return addr.balance;
    }
}*/

contract Provider {
    
    string providerName;
    address providerAddress;
    
    //TBD: using local name say SharedService for SharedStructs.Service: Later.
    SharedStructs.Service[] services;
    mapping(string => SharedStructs.Service) serviceByName;
    mapping(string => bool) servicesExisting;
        
    /**
     * Note: We do not need to deploy this contract. Just instantiate from Payments
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
    
    //TBD: Use modifier
    function offerService(string serviceName, uint256 servicePrice) public {
        if (servicesExisting[serviceName]) return;
        
        SharedStructs.Service memory srv= SharedStructs.Service(serviceName, servicePrice);
        services.push(srv);
        serviceByName[serviceName] = srv;
        servicesExisting[serviceName] = true;
    }
    
    function getServices() public view returns (SharedStructs.Service[]) {
        return services;
    }
    
    function doesServiceExist(string serviceName) public view returns (bool) {
        return servicesExisting[serviceName];
    }
    
    function getService(string serviceName) public view returns (SharedStructs.Service) {
        return serviceByName[serviceName];
    }
}

contract Payments {
    
    //Allows us to put some ether into the contract at deployment time
    //For testing that if the (service consumer) a/c does not pass in ether
    //the contract will still pay the service provider!
    //TBD: Add checks to prevent this, then remove this constructor
    constructor() public payable {
        //temp.
    }
    
    mapping(address => bool) private users;
    address[] private usersArray;

    mapping(string => bool) providersExistingByName;    
    mapping(string => Provider) providersByName;
    //mapping(address => bool) providersExistingByAddress;
    //mapping(address => Provider) providersByAddress;
    Provider[] providersArray;
    
    event Log_Value(string providerName, string serviceName, uint256 indexed value);
    event LogMoneyTransfer(address sender, address receiver, uint256 amount);
    
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
        
        providersArray.push(newProvider);
        providersByName[_provName]= newProvider;
        providersExistingByName[_provName]= true;
        
        //providersByAddress[msg_sender]= newProvider; //unique name & address for each provider. Fair enough?
        //providersExistingByAddress[msg_sender] = true;//TBD: Shd be providersExistingByAddress[newProvider]=true, oder??
    }
  
    function getProviders() public view returns (Provider[]) { 
        return providersArray;
    }
    
    //@TODO: Review. @see https://ethereum.stackexchange.com/questions/30665/warning-uninitialized-storage-pointer
    //@TODO: Also dunno how to get rid of "Warning: Uninitialized storage pointer"
    function getAllProviderNames() public returns (string[]) { 
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
    
    /*function getOffers(address providerAddr) public view returns (SharedStructs.Service[]) {
        if (!providersExistingByAddress[providerAddr]) return; 
        
        Provider prov= providersByAddress[providerAddr];
        return prov.getServices();        
    }*/
    
    function getOffers(string providerName) public view returns (SharedStructs.Service[]) {
        if (!providersExistingByName[providerName]) return;
        
        Provider provider= providersByName[providerName];
        return provider.getServices(); 
    }
    
    /*function getServicePriceFor(address providerAddress, string serviceName) public view returns (uint256) {
        if (!users[msg.sender]) return;
        bool exists= providersExistingByAddress[providerAddress];
        if (!exists) return;
        
        Provider provider= providersByAddress[providerAddress];
        if (!provider.doesServiceExist(serviceName)) return;
        
        SharedStructs.Service memory service= provider.getService(serviceName);
        uint256 serviceCost= service.price; 
        
        return serviceCost;
    }*/
    
    modifier providerExists(string providerName) {
        require (providersExistingByName[providerName]);
        _;
    }
    
    function getServicePriceFor(string providerName, string serviceName) providerExists(providerName) public view  returns (uint256) {
        //bool exists= providersExistingByName[providerName];
        //if (!exists) return 0;
        
        Provider provider= providersByName[providerName];
        bool srvcExists= provider.doesServiceExist(serviceName);
        if (!srvcExists) return 22;
        
        SharedStructs.Service memory service= provider.getService(serviceName);
        uint256 serviceCost= service.price; 
        
        return serviceCost;
    }
    
    //ToDo: Get this to work next
    /*function makePayment(address providerAddress, string serviceName) public payable {
        
        uint256 cost= getServicePriceFor(providerAddress, serviceName);
                
        // make payment -> substract money from caller [address: msg.sender], 
        //send money to the provider [address: providerAddress]
        //amount: serviceCost
        PaymentFunctions pf= new PaymentFunctions();
        //TODO BUG - serviceCost value comes to be 0 !!
        pf.deposit(cost); //Money from the user (msg.sender) to this contract.
        //pf.withdrawalByAddress(cost, providerAddress);
    }*/

    modifier isRegisteredConsumer() {
        require (users[msg.sender]);
        _;
    }
    
    //TBD: Handle errors
    function makePayment(string providerName, string serviceName) isRegisteredConsumer() public payable {
        //if (!users[msg.sender]) return;
                
        uint256 cost = getServicePriceFor(providerName, serviceName);
        emit Log_Value(providerName, serviceName, cost);
        // make payment -> subtract money from caller [address: msg.sender], 
        //send money to the provider [address: address of the providerName]
        //amount: serviceCost
        /*PaymentFunctions pf= new PaymentFunctions();
        //D newD = (new D).value(amount)(arg);
        pf.deposit(5555); //Money from the user (msg.sender) to this contract.
        
        Provider provider= providersByName[providerName];
        pf.withdrawalByAddress(4444, provider.getAddress());*/

/*
        //Step#1: Get money from the account (service consumer) into this contract
        deposit(cost); //TBD: how to get the account to transfer into this contract??
        //Works (only) if I give the amount in the "Value" in remix
        //How do I do this programmatically?

        //Step#2: Pay the service proider!
        Provider provider= providersByName[providerName];
        address addr= provider.getAddress();
        //addr.transfer(cost);
        withdrawalByAddress(cost, addr);
*/
        payProviderFromConsumer(providerName, cost);
    }
    
    
    ///////////////// Transfer Functions /////////////////////////////////////
    //TBD: Should move to Provider contract. Unless we consider gas costs in the design?
    function payProviderFromConsumer(string providerName, uint256 cost) public {
        
        //Step#1: Get money from the account (service consumer) into this contract
        deposit(cost); //TBD: how to get the account to transfer into this contract??
        //Works (only) if I give the amount in the "Value" in remix
        //How do I do this programmatically?

        //Step#2: Pay the service proider!
        Provider provider= providersByName[providerName];
        address addr= provider.getAddress();
        //addr.transfer(cost);
        withdrawalByAddress(cost, addr);
    }
    
    function deposit(uint256 amount) payable public {
        //require(msg.value == amount); TODO: CHK!
        // nothing else to do!
        emit LogMoneyTransfer(msg.sender, address(this), amount);
    }
    
    // address.transfer(amount) transfers amount (in ether) 
    // _TO_ the account represented by address.
    //
    function withdrawalByAddress(uint256 amount, address addr) payable public {
        addr.transfer(amount);
        emit LogMoneyTransfer(address(this), addr, amount);
    }
    
    //TBD: Is this still required??
    function () payable public {
    }
}