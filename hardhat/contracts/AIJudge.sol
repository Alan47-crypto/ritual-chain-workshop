// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AIBountyJudge {
    
    struct Bounty {
        address owner;
        uint256 reward;
        uint256 submissionDeadline;
        uint256 revealDeadline;
        bool isFinalized;
        address winner;
    }

    struct Submission {
        bytes32 commitment;
        string answer;
        bool isRevealed;
    }

    uint256 public bountyCounter;
    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => mapping(address => Submission)) public submissions;
    mapping(uint256 => address[]) public bountyParticipants;

    event BountyCreated(uint256 indexed bountyId, uint256 reward, uint256 submissionDeadline, uint256 revealDeadline);
    event CommitmentSubmitted(uint256 indexed bountyId, address indexed participant);
    event AnswerRevealed(uint256 indexed bountyId, address indexed participant);
    event JudgingRequested(uint256 indexed bountyId);
    event WinnerFinalized(uint256 indexed bountyId, address indexed winner);

    // 1. Owner creates a bounty
    function createBounty(uint256 _submissionDeadline, uint256 _revealDeadline) external payable returns (uint256) {
        require(_submissionDeadline > block.timestamp, "Invalid submission deadline");
        require(_revealDeadline > _submissionDeadline, "Invalid reveal deadline");
        
        uint256 bountyId = ++bountyCounter;
        bounties[bountyId] = Bounty({
            owner: msg.sender,
            reward: msg.value,
            submissionDeadline: _submissionDeadline,
            revealDeadline: _revealDeadline,
            isFinalized: false,
            winner: address(0)
        });
        
        emit BountyCreated(bountyId, msg.value, _submissionDeadline, _revealDeadline);
        return bountyId;
    }

    // 2. Participants submit only a commitment hash
    function submitCommitment(uint256 bountyId, bytes32 commitment) external {
        Bounty storage bounty = bounties[bountyId];
        require(block.timestamp <= bounty.submissionDeadline, "Submission phase ended");
        require(submissions[bountyId][msg.sender].commitment == bytes32(0), "Commitment already submitted");

        submissions[bountyId][msg.sender].commitment = commitment;
        bountyParticipants[bountyId].push(msg.sender);
        
        emit CommitmentSubmitted(bountyId, msg.sender);
    }

    // 4 & 5. Participants reveal their answer and the contract verifies it
    function revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt) external {
        Bounty storage bounty = bounties[bountyId];
        require(block.timestamp > bounty.submissionDeadline, "Submission phase still active");
        require(block.timestamp <= bounty.revealDeadline, "Reveal phase ended");
        
        Submission storage sub = submissions[bountyId][msg.sender];
        require(sub.commitment != bytes32(0), "No commitment found");
        require(!sub.isRevealed, "Already revealed");

        bytes32 expectedCommitment = keccak256(abi.encodePacked(answer, salt, msg.sender, bountyId));
        require(sub.commitment == expectedCommitment, "Invalid reveal parameters");

        sub.answer = answer;
        sub.isRevealed = true;
        
        emit AnswerRevealed(bountyId, msg.sender);
    }

    // 7 & 8. Owner requests AI judging after reveal deadline
    function judgeAll(uint256 bountyId, bytes calldata llmInput) external {
        Bounty storage bounty = bounties[bountyId];
        require(msg.sender == bounty.owner, "Only owner can judge");
        require(block.timestamp > bounty.revealDeadline, "Reveal phase still active");
        require(!bounty.isFinalized, "Bounty already finalized");

        // Logic to trigger Ritual AI execution goes here
        // The LLM will receive the revealed answers and the llmInput for evaluation.
        
        emit JudgingRequested(bountyId);
    }

    // 9. Owner finalizes one winner and pays the reward
    function finalizeWinner(uint256 bountyId, uint256 winnerIndex) external {
        Bounty storage bounty = bounties[bountyId];
        require(msg.sender == bounty.owner, "Only owner can finalize");
        require(block.timestamp > bounty.revealDeadline, "Reveal phase still active");
        require(!bounty.isFinalized, "Bounty already finalized");
        
        address[] memory participants = bountyParticipants[bountyId];
        require(winnerIndex < participants.length, "Invalid winner index");
        
        address winnerAddress = participants[winnerIndex];
        require(submissions[bountyId][winnerAddress].isRevealed, "Winner must have revealed");

        bounty.isFinalized = true;
        bounty.winner = winnerAddress;

        (bool success, ) = winnerAddress.call{value: bounty.reward}("");
        require(success, "Transfer failed");

        emit WinnerFinalized(bountyId, winnerAddress);
    }
}
