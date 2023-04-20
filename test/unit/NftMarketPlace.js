const { assert, expect } = require("chai");
const { network, deployments, ether } = require("hardhat");
const { developmentChains } = require("../../helper-config-hardhat");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe(" NFT market place tests", function () {
          let nftMarketplace, nftMarketPlaceContract, basicNft, basicNftContract;
          const PRICE = ethers.utils.parseEther("0.01");
          const TOKEN_ID = 0;
          let accounts, deployer, user;
          beforeEach(async () => {
              accounts = await ethers.getSigners();
              deployer = accounts[0];
              user = accounts[1];

              await deployments.fixture(["all"]);
              nftMarketPlaceContract = await ethers.getContract("NFTMarketplace");
              nftMarketplace = nftMarketPlaceContract.connect(deployer);
              basicNftContract = await ethers.getContract("BasicNft");
              basicNft = await basicNftContract.connect(deployer);

              await basicNft.mintNft();
              await basicNft.approve(nftMarketPlaceContract.address, TOKEN_ID);
          });

          describe("listItem", () => {
              it("emits event after listing item", async () => {
                  expect(await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)).to.emit(
                      "eventItemListed"
                  );
              });

              it("no duplicate listing", async () => {
                  await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE);
                  const error = `'NFTMarketplace__ItemAlreadyListed("${basicNft.address}", ${TOKEN_ID})'`;
                  await expect(
                      nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)
                  ).to.be.revertedWith(error);
              });

              it("Allow only owner to list nft", async () => {
                  nftMarketplace = await nftMarketPlaceContract.connect(user);
                  const error = `'NFTMarketplace__InvalidOwner("${basicNft.address}", ${TOKEN_ID})'`;
                  //   await basicNft.approve(user.address, TOKEN_ID);
                  await expect(
                      nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)
                  ).to.be.revertedWith(error);
              });

              it("Need approval for listing nft", async () => {
                  // nftMarketplace = await nftMarketPlaceContract.connect(user);
                  await basicNft.approve(ethers.constants.AddressZero, TOKEN_ID); // it only can have 1 approved address. So now nftMarketplace is not in approved list
                  await expect(
                      nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)
                  ).to.be.revertedWith("NFTMarketplace__NotApprovedForMarketplace");
              });

              it("update the listing", async () => {
                  await basicNft.approve(nftMarketplace.address,TOKEN_ID);
                  await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE);
                  const listing = await nftMarketplace.getListing(basicNft.address, TOKEN_ID);
                  assert(listing.price.toString() == PRICE.toString());
                  assert(listing.seller.toString() == deployer.address);
              });
          });
      });
