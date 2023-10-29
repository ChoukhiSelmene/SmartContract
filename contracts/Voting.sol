// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable(msg.sender) {

    mapping(address => Voter) public whiteList;
    mapping(uint => Proposal) public proposals;
    uint public numProposals;
    WorkflowStatus public currentWorkflowStatus = WorkflowStatus.VotesTallied;

    // Modifiers //

    modifier onlyInStatus(WorkflowStatus _requiredStatus) {
        require(currentWorkflowStatus == _requiredStatus, "Invalid workflow status");
        _;
    }

    // Fonctions //

        // Général //

    function setWorkflowStatus(WorkflowStatus _newStatus) private {
        emit WorkflowStatusChange(currentWorkflowStatus, _newStatus);
        currentWorkflowStatus = _newStatus;
    }


        // Liste Blanche //
        
    function addAddressToWhiteList(address _newAddress) public onlyOwner {
        whiteList[_newAddress] = Voter({isRegistered: true, hasVoted: false, votedProposalId: 0, points: 0}); // Ajoute l'adresse à la liste blanche
        emit VoterRegistered(_newAddress);
    }

    function removeAddressFromWhiteList(address _addressToRemove) public onlyOwner {
        delete whiteList[_addressToRemove]; // Retire l'adresse de la liste blanche
        emit VoterUnRegistered(_addressToRemove);
    }

        // Workflow //
    function beginRegisteringVotes() public onlyOwner{            
        setWorkflowStatus(WorkflowStatus.RegisteringVoters);
        emit WorkflowStatusChange(WorkflowStatus.VotesTallied, currentWorkflowStatus);
    }

    function beginRegisteringProposals() public onlyOwner{            
        setWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, currentWorkflowStatus);
    }

    function beginVotingSession() public onlyOwner{
        setWorkflowStatus(WorkflowStatus.VotingSessionStarted);
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, currentWorkflowStatus);
    }

    function stopVotingSession() public onlyOwner {
        setWorkflowStatus(WorkflowStatus.VotesTallied);
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, currentWorkflowStatus);
    }

        // Vote //
    function addProposal(uint _proposalId, string memory _description) public {
        proposals[_proposalId] = Proposal({creator: msg.sender, description: _description, voteCount: 0});
        numProposals++;
        emit ProposalRegistered(_proposalId);
    }

    function removeProposal(uint _proposalId) public onlyOwner{
        delete proposals[_proposalId];
        numProposals--;
        emit ProposalUnregistered(_proposalId);
    }

    function votes(uint _proposalId) public {
        require(whiteList[msg.sender].isRegistered, "You are not registered as a voter");
        require(!whiteList[msg.sender].hasVoted, "You have already voted");

        require(currentWorkflowStatus == WorkflowStatus.VotingSessionStarted, "Voting session has not started yet");

        require(_proposalId < numProposals, "Invalid proposal ID");

        proposals[_proposalId].voteCount++;
        whiteList[msg.sender].hasVoted = true;
        whiteList[msg.sender].votedProposalId = _proposalId;

        emit Voted(msg.sender, _proposalId);
    }
    
        // Autres //

    function getWinner() public returns (uint) {
        require(currentWorkflowStatus == WorkflowStatus.VotesTallied, "Voting session has not ended yet");

        uint winningProposalId;
        uint maxVoteCount = 0;

        for (uint i = 0; i < numProposals; i++) {
            if (proposals[i].voteCount > maxVoteCount) {
                maxVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }

        whiteList[proposals[winningProposalId].creator].points = maxVoteCount;

        return winningProposalId;
    }

    // Structures //

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
        uint points;
    }

    struct Proposal {
        address creator;
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // Évenements //

    event VoterRegistered(address voterAddress);
    event VoterUnRegistered(address voterAddress);
    event UnauthorizedVoter(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event ProposalUnregistered(uint proposalId);
    event Voted (address voter, uint proposalId);

}