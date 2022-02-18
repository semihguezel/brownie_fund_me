// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

//We import this library for checking overflow in math for integer numbers
//Starting from 0.8.0 we don't need to use it because they implemented this mechanism in soldity
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    //Variables inside of the constructor function will immediately executed while smart contract is deployed
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // Functions and addresses declared payable can receive ether into the contract.
    // Function to fund Ether into this contract.
    function fund() public payable {
        uint256 minUSD = 50 * 10**18;
        //require is a function that checks the statement inside of it
        //If it's satifies the condition function inside of it executes
        //Else function will not be executed and revets the action which means there will be no gas fees to be payed
        require(
            getConvertionRate(msg.value) >= minUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //Each smart contrat deployed on chain has a contract adress in order to interact with
        //smart contracts we have to pass in their adresses
        //in this particular example we passed eth/usd price feed for rinkeby testnet
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        //This is the tuple decleration, since we only need 1 attribute of the latesRoundData
        //Function we only passed in answer variable, but our function returns 5 value
        //In order to solve this problem we replaced unnecessary varibles with blank thats why we have bunch of ","
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // Current answer has 8 decimals in order to convert it wei's we mulpil with 10**10
        return uint256(answer * 10000000000);
    }

    function getConvertionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(); //In wei units
        uint256 ethAmounInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmounInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    //modifiers can be used for functions to be able to check certain conditions.
    modifier onlyOwner() {
        //Before the function starts it will check this condition first
        require(msg.sender == owner);
        //"_" this represents run the rest of the code in the function that we will call
        _;
    }

    //We modified our function in a way that it checks wheter the caller of this function is
    //owner of the adress where smart contract is first deployed or not.
    function withdraw() public payable onlyOwner {
        //this keyword refers the contract that we are currently in
        //Who ever calls this function we are transferring all of our money that we have in this adress
        msg.sender.transfer(address(this).balance);
        //We reset stored data in addressToAmountFunded variable to 0 after withdrawal
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //We reset the size of the funders array to 0 after withdrawal
        funders = new address[](0);
    }
}
