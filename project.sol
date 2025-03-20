// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedGigEconomy {

    enum GigStatus { Posted, InProgress, Completed, Canceled }

    struct Gig {
        uint256 id;
        address employer;
        address freelancer;
        string description;
        uint256 paymentAmount;
        GigStatus status;
    }

    uint256 public gigCounter;
    mapping(uint256 => Gig) public gigs;
    mapping(address => uint256) public balances;

    event GigPosted(uint256 gigId, address employer, string description, uint256 paymentAmount);
    event GigAccepted(uint256 gigId, address freelancer);
    event GigCompleted(uint256 gigId, address freelancer);
    event PaymentReleased(uint256 gigId, address freelancer, uint256 paymentAmount);
    event GigCanceled(uint256 gigId, address employer);

    modifier onlyEmployer(uint256 _gigId) {
        require(msg.sender == gigs[_gigId].employer, "Only the employer can perform this action");
        _;
    }

    modifier onlyFreelancer(uint256 _gigId) {
        require(msg.sender == gigs[_gigId].freelancer, "Only the freelancer can perform this action");
        _;
    }

    modifier gigExists(uint256 _gigId) {
        require(gigs[_gigId].id != 0, "Gig does not exist");
        _;
    }

    modifier gigPosted(uint256 _gigId) {
        require(gigs[_gigId].status == GigStatus.Posted, "Gig is not in posted state");
        _;
    }

    modifier gigInProgress(uint256 _gigId) {
        require(gigs[_gigId].status == GigStatus.InProgress, "Gig is not in progress");
        _;
    }

    modifier gigCompleted(uint256 _gigId) {
        require(gigs[_gigId].status == GigStatus.Completed, "Gig is not completed");
        _;
    }

    modifier hasEnoughFunds(uint256 _amount) {
        require(balances[msg.sender] >= _amount, "Insufficient funds");
        _;
    }

    // Employer posts a new gig
    function postGig(string memory _description, uint256 _paymentAmount) external {
        require(_paymentAmount > 0, "Payment amount must be greater than 0");

        gigCounter++;
        gigs[gigCounter] = Gig({
            id: gigCounter,
            employer: msg.sender,
            freelancer: address(0),
            description: _description,
            paymentAmount: _paymentAmount,
            status: GigStatus.Posted
        });

        emit GigPosted(gigCounter, msg.sender, _description, _paymentAmount);
    }

    // Employer cancels a gig (only if the gig is still in posted state)
    function cancelGig(uint256 _gigId) external onlyEmployer(_gigId) gigPosted(_gigId) {
        gigs[_gigId].status = GigStatus.Canceled;
        emit GigCanceled(_gigId, msg.sender);
    }

    // Freelancer accepts the gig and starts working on it
    function acceptGig(uint256 _gigId) external gigPosted(_gigId) {
        Gig storage gig = gigs[_gigId];
        gig.freelancer = msg.sender;
        gig.status = GigStatus.InProgress;

        emit GigAccepted(_gigId, msg.sender);
    }

    // Employer marks the gig as completed
    function completeGig(uint256 _gigId) external onlyEmployer(_gigId) gigInProgress(_gigId) {
        Gig storage gig = gigs[_gigId];
        gig.status = GigStatus.Completed;

        emit GigCompleted(_gigId, gig.freelancer);
    }

    // Release payment to the freelancer once the gig is completed
    function releasePayment(uint256 _gigId) external onlyEmployer(_gigId) gigCompleted(_gigId) hasEnoughFunds(gigs[_gigId].paymentAmount) {
        Gig storage gig = gigs[_gigId];
        
        // Transfer payment to freelancer
        balances[msg.sender] -= gig.paymentAmount;
        balances[gig.freelancer] += gig.paymentAmount;

        emit PaymentReleased(_gigId, gig.freelancer, gig.paymentAmount);
    }

    // Employer deposits funds to their account in the platform
    function depositFunds() external payable {
        balances[msg.sender] += msg.value;
    }

    // Check balance of the sender
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    // View gig details
    function getGigDetails(uint256 _gigId) external view returns (Gig memory) {
        return gigs[_gigId];
    }
}
