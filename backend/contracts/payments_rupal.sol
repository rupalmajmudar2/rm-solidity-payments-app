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
        
    constructor() public payable {
        //to be removed
    }
    
    function withdrawAll() public {
        msg.sender.transfer(address(this).balance);
    }

    /*
     * address.transfer(amount) transfers amount (in ether) 
     * _TO_ the sender
     */
    function withdraw(uint256 amount) payable public {
        msg.sender.transfer(amount);
        //emit LogMoneyTransfer(address(this), msg.sender, amount);
    }
    
    /*
     * address.transfer(amount) transfers amount (in ether) 
     * _TO_ the account represented by address.
     */
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
     * Or: We shd never deploy this contract, just instantiate from Payments??
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
    
    constructor() public payable {
        
    }
    
    mapping(address => bool) private users;
    address[] private usersArray;

    mapping(string => bool) providersExistingByName;    
    mapping(string => Provider) providersByName;
    mapping(address => bool) providersExistingByAddress;
    mapping(address => Provider) providersByAddress;
    Provider[] providersArray;
    
    event test_value(uint256 indexed value1);
    
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
        providersExistingByAddress[msg_sender] = true;//TBD: Shd be providersExistingByAddress[newProvider]=true, oder??
        providersExistingByName[_provName]= true;
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
    
    function makePayment(string providerName, string serviceName) public payable {
       // if (!users[msg.sender]) return;
                
        uint256 cost = getServicePriceFor(providerName, serviceName);
                emit test_value(cost);
        // make payment -> substract money from caller [address: msg.sender], 
        //send money to the provider [address: address of the providerName]
        //amount: serviceCost
        /*PaymentFunctions pf= new PaymentFunctions();
        //D newD = (new D).value(amount)(arg);
        pf.deposit(5555); //Money from the user (msg.sender) to this contract.
        
        Provider provider= providersByName[providerName];
        pf.withdrawalByAddress(4444, provider.getAddress());*/

        deposit(cost); //TBD: how to get the account to transfer into this contract??
        //Works (only) if I give the amount in the "Value" in remix
        //How do I do this programmatically?

        Provider provider= providersByName[providerName];
        address addr= provider.getAddress();
        addr.transfer(cost);
    }
    
    function deposit(uint256 amount) payable public {
        //require(msg.value == amount); TODO: CHK!
        // nothing else to do!
        //emit LogMoneyTransfer(msg.sender, address(this), amount);
    }
    
    function () payable public {
    }
}