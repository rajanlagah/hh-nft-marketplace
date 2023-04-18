const { assert, expect } = require("chai");
const { network , deployments , ether} = require("hardhat");
const { developmentChains } = require("../../helper-config-hardhat");


!developmentChains.includes(network.name)
    ? describe.skip:
    describe(" NFT market place tests", function(){
        
    })