const { network } = require("hardhat");
const { developmentChains } = require("../helper-config-hardhat");
const { verifyContract } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    let args = [];

    const nftMarketPlace = await deploy("NFTMarketplace", {
        from: deployer,
        args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    if (!developmentChains.includes(network.name) && process.env.ETHER_SCAN_API_KEY) {
        log("--------- verifying ----------");
        await verifyContract(nftMarketPlace.address, args);
    }

    log(" ----------------------- ");
};

module.exports.tags = ["all", "nftmarketplace"];
