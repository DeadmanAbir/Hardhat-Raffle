require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()
require("@nomiclabs/hardhat-ethers")


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      blockConfirmations: 1
    },
    rinekby: {
      chainId: 4,
      blockConfirmations: 6,
      url: process.env.RINKEBY_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  solidity: "0.8.8",
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
    player: {
      default: 1,
    },
  },
};
