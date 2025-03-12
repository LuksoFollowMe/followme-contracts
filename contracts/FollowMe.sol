// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface UniversalProfile {
    function execute(
        uint256 operationType,
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function getData(bytes32 key) external view returns (bytes memory);
}

interface FollowerSystem {
    function isFollowing(
        address follower,
        address addr
    ) external view returns (bool);

    function followerCount(address addr) external view returns (uint256);

    function getFollowersByIndex(
        address addr,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (address[] memory);
}

contract FollowMe {
    address private immutable FOLLOWER_CONTRACT;

    struct Campaign {
        uint256 amount;
        uint256 amountLeft;
    }

    mapping(address => Campaign) private _campaigns;
    mapping(address => mapping(address => bool)) private _followers;

    error InvalidAmount();
    error CampaignNotAvailable();
    error InsufficientFunds();
    error NotAUniversalProfile();
    error NotFollowing();
    error AlreadyCollected();

    constructor(address _followerContract) payable {
        FOLLOWER_CONTRACT = _followerContract;
    }

    function startCampaign(Campaign memory campaign) public payable {
        if (
            campaign.amount == 0 ||
            campaign.amountLeft == 0 ||
            campaign.amountLeft % campaign.amount != 0
        ) revert InvalidAmount();

        if (_campaigns[msg.sender].amount > 0) {
            cancelCampaign();
        }

        FollowerSystem externalFollowers = FollowerSystem(FOLLOWER_CONTRACT);
        uint256 followerCount = externalFollowers.followerCount(msg.sender);

        for (uint256 i = 0; i < followerCount; i += 50) {
            uint256 endIndex = (i + 50 > followerCount)
                ? followerCount
                : (i + 50);
            address[] memory followers = externalFollowers.getFollowersByIndex(
                msg.sender,
                i,
                endIndex
            );

            for (uint256 j = 0; j < followers.length; ++j) {
                if (!_followers[msg.sender][followers[j]]) {
                    _followers[msg.sender][followers[j]] = true;
                }
            }
        }

        _campaigns[msg.sender] = campaign;
    }

    function cancelCampaign() public payable {
        delete _campaigns[msg.sender];
    }

    function getCampaign(address account) public view returns (uint256 amount) {
        if (_campaigns[account].amountLeft > 0) {
            return _campaigns[account].amount;
        }
        return 0;
    }

    function isFollowing(
        address account,
        address follower
    ) public view returns (bool, bool) {
        return _isFollowing(account, follower);
    }

    function collect(address account) public payable returns (bool) {
        if (
            _campaigns[account].amount == 0 ||
            _campaigns[account].amountLeft == 0
        ) revert CampaignNotAvailable();
        if (address(account).balance < _campaigns[account].amount)
            revert InsufficientFunds();
        if (!_isUniversalProfile(msg.sender)) revert NotAUniversalProfile();

        (bool externalFollowing, bool internalFollowing) = _isFollowing(
            account,
            msg.sender
        );

        if (internalFollowing) revert AlreadyCollected();
        if (!externalFollowing) revert NotFollowing();

        _campaigns[account].amountLeft -= _campaigns[account].amount;
        _followers[account][msg.sender] = true;

        UniversalProfile up = UniversalProfile(account);

        try up.execute(0, msg.sender, _campaigns[account].amount, "") {} catch {
            revert("UP failed to transfer funds");
        }

        return true;
    }

    function _isUniversalProfile(address account) internal view returns (bool) {
        UniversalProfile up = UniversalProfile(account);
        try up.supportsInterface(0x24871b3d) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    function _isFollowing(
        address account,
        address follower
    ) internal view returns (bool, bool) {
        FollowerSystem externalFollowers = FollowerSystem(FOLLOWER_CONTRACT);
        return (
            externalFollowers.isFollowing(follower, account),
            _followers[account][follower]
        );
    }
}
