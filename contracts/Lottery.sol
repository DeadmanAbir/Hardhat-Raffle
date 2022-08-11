// SPDX-License-Identifier:MIT

pragma solidity >0.8.6;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface{

    enum raffleState{
        open, 
        calculating
    }

    uint256 private immutable fee;
    address[] private players;
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    bytes32 private immutable i_gaslane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant requestConfirmation=3;
    uint32 private immutable i_callBackgasLimit;
    uint16 private constant NUM_WORDS=1;
    address private s_recentWinner;
    raffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable interval;

    event raffleEnter(address indexed player);
    event requestedRaffleWinner(uint256 indexed requested_winner);
    event winnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2, 
        uint256 _amount, 
        bytes32 _gaslane, 
        uint64 subscriptionId, 
        uint32 _gasLimit,
        uint256 _interval
        ) VRFConsumerBaseV2(vrfCoordinatorV2){
        fee=_amount;
        vrfCoordinator=VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gaslane=_gaslane;
        i_subscriptionId=subscriptionId;
        i_callBackgasLimit=_gasLimit;
        s_raffleState=raffleState.open;
        s_lastTimeStamp=block.timestamp;
        interval=_interval;
    }

    function getFee()public view returns(uint256){
        return fee;
    }

    function getPlayer(uint256 _index)public view returns(address){
        return players[_index];
    }
    
    function getRecentWinner()public view returns(address){
        return s_recentWinner;
    }

    function enterRaffle()public payable{
        require(msg.value>=fee,"Pay the minimum fee to take part");
        require(s_raffleState!=raffleState.open, "Lottery is closed!");
        players.push(msg.sender);
        emit raffleEnter(msg.sender);

    }

     function checkUpkeep(bytes memory)public override returns(bool upkeepNeeded, bytes memory){
        bool isOpen=(raffleState.open == s_raffleState);
        bool timePassed= ((block.timestamp - s_lastTimeStamp)> interval);
        bool hasPlayers=((players.length)>=0);
        bool hasBalance=((address(this).balance)>0);
        upkeepNeeded=(isOpen && timePassed && hasPlayers && hasBalance);
        // return (upkeepNeeded, "");

    }

    function performUpkeep(bytes calldata /* performData */)external override{
        (bool upkeepNeeded, )=checkUpkeep("");
        require(upkeepNeeded, "checkUpKeep not needed");
        s_raffleState=raffleState.calculating;
        uint256 request_id=vrfCoordinator.requestRandomWords(
            i_gaslane, 
            i_subscriptionId, 
            requestConfirmation, 
            i_callBackgasLimit, 
            NUM_WORDS
            );
       
        emit requestedRaffleWinner(request_id);
    }

   

    function fulfillRandomWords(uint256, uint256[] memory randomWords)internal override{
        uint256 index=randomWords[0]%players.length;
        address recentWinner=players[index];
        s_recentWinner=recentWinner;
        s_raffleState=raffleState.open;
        delete players;
        s_lastTimeStamp=block.timestamp;
        (bool success, )=payable(recentWinner).call{value: address(this).balance}("");
        require(success, "Transfer Failed");
        emit winnerPicked(recentWinner);
    }

    function getRaffleState()public view returns(raffleState){
        return s_raffleState;
    }

    function getNumWords()public pure returns(uint256){
        return NUM_WORDS;
    }

    function getNumberofPlayers()public view returns(uint256){
        return players.length;
    }

    function getLatestTimeStamp()public view returns(uint256){
        return s_lastTimeStamp;
    }

    function getRequestConfirmtion()public pure returns(uint256){
        return requestConfirmation;
    }


}