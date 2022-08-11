const { networks } = require("../hardhat.config");
const{ethers, network}=require("hardhat");
const{developmentChains, networkConfig}=require("../helper-hardhat-config");
const{verify}=require("../utils/verify");

const fundSub=ethers.utils.parseEther("2");

module.exports=async({getNamedAccounts, deployments})=>{
    const {deploy, log}=deployments;
    const {deployer}=await getNamedAccounts();
    const chainIds=network.config.chainId;
    let chainlinkAddress, subId;
    const entranceFee=networkConfig[chainIds]["fee"];
    const gasLane=networkConfig[chainIds]["gasLane"];
    const gasLimit=networkConfig[chainIds]["callBackGasLimit"];
    const interval=networkConfig[chainIds]["interval"];

    if(developmentChains.includes(network.name)){
        const vrfCoordinatorV2Mock=await ethers.getContract("VRFCoordinatorV2Mock");
        chainlinkAddress=vrfCoordinatorV2Mock.address;
        const receipt=await vrfCoordinatorV2Mock.createSubscription();
        const response= await receipt.wait(1);
        subId=response.receipt.events[0].args.subId;//getting the subId from the event emitted from the function in mock contract
        await vrfCoordinatorV2Mock.fundSubscription(subId, fundSub);
        
    }else{
        chainlinkAddress=networkConfig[chainIds]["vrfCoordinatorV2"];
        subId=networkConfig[chainIds]["subId"];
    }

    

    const raffle=await deploy("Lottery", {
        from: deployer,
        args: [chainlinkAddress, entranceFee, gasLane, subId, gasLimit, interval],
        log: true,
        waitConfirmations: networks.blockConfirmations || 1
    })

    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API){
        log("verifiying");
        verify(raffle.address, [chainlinkAddress, entranceFee, gasLane, subId, gasLimit, interval]);
    }
    log("_________________________________________________________!")
}

module.exports.tags=["all", "raffle"]