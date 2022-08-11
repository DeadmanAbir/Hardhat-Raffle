const {developmentChains}=require("./helper-hardhat-config");
const{getNamedAccounts, deployments, network, ethers}=require("hardhat");

const baseFee=ethers.utils.parseEther("0.25");
const gasFee= 1e9;

module.exports=async function({getNamedAccounts, deployments}){
    const {deploy, log}=deployments;
    const {deployer}=await getNamedAccounts();
    const chainId=network.config.chainId;

    if(chainId==31337/*developmentChains.includes(network.name)*/){
        console.log("Local network detected, Deploying Mocks !");

        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: [baseFee, gasFee]
        })
    }
    log("Mocks Deployed");
    log("!-------------------------------------------------------------")

}
module.exports.tags=["all", "mocks"]
