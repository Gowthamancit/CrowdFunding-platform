// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        bool claimed; // Tracks if the owner has withdrawn funds
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    // Mapping to track how much a specific address donated to a specific campaign
    // campaignId => (donorAddress => amountDonated)
    mapping(uint256 => mapping(address => uint256)) public contributions;

    // EVENTS (For frontend updates)
    event CampaignCreated(uint256 id, address owner, string title, uint256 target, uint256 deadline);
    event DonationReceived(uint256 id, address donor, uint256 amount);
    event RefundIssued(uint256 id, address donor, uint256 amount);

    /**
     * @dev Create a new crowdfunding campaign
     * @param _deadline is the unix timestamp for when the campaign ends
     */
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        // Validation: Deadline must be in the future
        require(_deadline > block.timestamp, "The deadline must be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.claimed = false;

        numberOfCampaigns++;

        emit CampaignCreated(numberOfCampaigns - 1, _owner, _title, _target, _deadline);

        return numberOfCampaigns - 1;
    }

    /**
     * @dev Donate ETH to a specific campaign
     */
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        // 1. Check if deadline has passed
        require(block.timestamp < campaign.deadline, "Campaign has ended.");
        
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        // Update tracking
        campaign.amountCollected = campaign.amountCollected + amount;
        contributions[_id][msg.sender] = contributions[_id][msg.sender] + amount;

        emit DonationReceived(_id, msg.sender, amount);
    }

    /**
     * @dev Withdraw funds (ONLY for Campaign Owner if target is met)
     */
    function withdrawFunds(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];

        require(msg.sender == campaign.owner, "Only the owner can withdraw.");
        require(block.timestamp > campaign.deadline, "Campaign is still ongoing.");
        require(campaign.amountCollected >= campaign.target, "Target amount was not reached.");
        require(!campaign.claimed, "Funds already claimed.");

        campaign.claimed = true;

        (bool sent, ) = payable(campaign.owner).call{value: campaign.amountCollected}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Claim Refund (ONLY for Donors if target is NOT met)
     */
    function claimRefund(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];

        // 1. Logic: Can only refund if deadline passed AND target NOT met
        require(block.timestamp > campaign.deadline, "Campaign is not over yet.");
        require(campaign.amountCollected < campaign.target, "Campaign succeeded! You cannot refund.");

        // 2. Check how much the caller donated
        uint256 donatedAmount = contributions[_id][msg.sender];
        require(donatedAmount > 0, "You have no funds to refund.");

        // 3. Reset contribution to prevent re-entrancy attacks
        contributions[_id][msg.sender] = 0;

        // 4. Send ETH back
        (bool sent, ) = payable(msg.sender).call{value: donatedAmount}("");
        require(sent, "Failed to refund Ether");

        emit RefundIssued(_id, msg.sender, donatedAmount);
    }

    // Helper to get list of donators and donations
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    // Helper to get all campaigns
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}