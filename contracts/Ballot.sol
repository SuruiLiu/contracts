// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0 <0.9.0;

contract Ballot{

    struct Voter{
        uint weight;
        address delegate;
        bool voted;
        uint index; //proposal index
    }

    struct Proposal{
        bytes32 name;
        uint num;
    }

    address public chairperson;

    mapping (address => Voter) voters;

    Proposal[] public proposals;

    constructor(bytes32[] memory proposalsNames){
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for(uint i  = 0; i < proposalsNames.length; i++){
            proposals.push(Proposal({
                name : proposalsNames[i],
                num : 0
            }));
        }
    }

    function giveRightToVoter(address voter) external {
        require(msg.sender == chairperson, "only chairperson can give rigth to voter");
        require(!voters[voter].voted);
        require(voters[voter].weight == 0);
        voters[voter].weight = 1; 
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        require(sender.weight != 0);
        require(sender.delegate != msg.sender);

        while(voters[to].delegate != address(0)){
            to = voters[to].delegate;
            require(to != msg.sender);
        }

        Voter storage delegate_ = voters[to];

        sender.voted = true;
        sender.delegate = to;

        require(delegate_.weight >= 1);
        if(delegate_.voted){
            proposals[delegate_.index].num += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        require(sender.weight >= 1);
        sender.voted = true;
        sender.index = proposal;

        proposals[proposal].num += sender.weight;        
    }

    // view
    function winningProposal() public view returns(uint winningProposal_){
        uint winningVoteNum = 0;
        for(uint p = 0; p < proposals.length; p++){
            if(proposals[p].num > winningVoteNum){
                winningProposal_ = p;
                winningVoteNum = proposals[p].num;
            }
        }
    } 

    function winnerName() external view returns(bytes32 proposalName_){
        proposalName_ = proposals[winningProposal()].name;
    }
}