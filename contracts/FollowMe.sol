// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@lukso/lsp-smart-contracts/contracts/LSP1UniversalReceiver/ILSP1UniversalReceiverDelegate.sol";

interface UniversalProfile {
    function execute(
        uint256 operationType,
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function setData(bytes32 dataKey, bytes memory dataValue) external payable;
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

contract FollowMe is ILSP1UniversalReceiverDelegate {
    address private constant FOLLOWER_CONTRACT =
        0xf01103E5a9909Fc0DBe8166dA7085e0285daDDcA;
    address private constant NATIVE = address(0);
    bytes32 constant LSP26_FOLLOWED_TYPEID =
        0x71e02f9f05bcd5816ec4f3134aa2e5a916669537ec6c77fe66ea595fabc2d51a;
    bytes32 constant RECEIVER_DELEGATE_KEY =
        0x0cfc51aec37c55a4d0b1000071e02f9f05bcd5816ec4f3134aa2e5a916669537;

    struct Campaign {
        address assetAddress;
        uint256 amount;
        uint256 amountLeft;
    }

    mapping(address => Campaign) private _campaigns;
    mapping(address => mapping(address => bool)) private _followers;

    error InvalidAmount();
    error NotAUniversalProfile();

    event FollowerSend(
        address indexed from,
        address to,
        address assets,
        uint256 value
    );

    constructor() payable {}

    function startCampaign(
        Campaign memory campaign,
        bool registerReceiverDelegate
    ) public payable {
        if (
            campaign.amount == 0 ||
            campaign.amountLeft == 0 ||
            campaign.amountLeft % campaign.amount != 0
        ) revert InvalidAmount();

        if (!_isUniversalProfile(msg.sender)) revert NotAUniversalProfile();

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

        if (registerReceiverDelegate) {
            _registerReceiverDelegate();
        }

        _campaigns[msg.sender] = campaign;
    }

    function cancelCampaign() public payable {
        delete _campaigns[msg.sender];
    }

    function registerReceiverDelegate() public payable {
        _registerReceiverDelegate();
    }

    function getCampaign(
        address account
    ) public view returns (uint256 amount, address assetAddress) {
        if (_campaigns[account].amountLeft > 0) {
            return (
                _campaigns[account].amount,
                _campaigns[account].assetAddress
            );
        }
        return (0, address(0));
    }

    function isFollowing(
        address account,
        address follower
    ) public view returns (bool, bool) {
        return _isFollowing(account, follower);
    }

    function universalReceiverDelegate(
        address,
        uint256,
        bytes32 typeId_,
        bytes memory data_
    ) external override returns (bytes memory) {
        if (typeId_ != LSP26_FOLLOWED_TYPEID) return "";

        address follower = address(uint160(bytes20(data_)));

        if (
            _campaigns[msg.sender].amount == 0 ||
            _campaigns[msg.sender].amountLeft == 0
        ) {
            return "";
        }

        if (!_isUniversalProfile(follower)) {
            return "";
        }

        (bool externalFollowing, bool internalFollowing) = _isFollowing(
            msg.sender,
            follower
        );

        if (internalFollowing || !externalFollowing) {
            return "";
        }

        _campaigns[msg.sender].amountLeft -= _campaigns[msg.sender].amount;
        _followers[msg.sender][follower] = true;

        UniversalProfile up = UniversalProfile(msg.sender);

        if (_campaigns[msg.sender].assetAddress == NATIVE) {
            try
                up.execute(0, follower, _campaigns[msg.sender].amount, "")
            {} catch {
                revert("UP failed to transfer funds");
            }
        } else {
            bytes memory transferData;
            transferData = abi.encodeWithSignature(
                "transfer(address,address,uint256,bool,bytes)",
                msg.sender,
                follower,
                _campaigns[msg.sender].amount,
                true,
                ""
            );

            try
                up.execute(
                    0,
                    _campaigns[msg.sender].assetAddress,
                    0,
                    transferData
                )
            {} catch {
                revert("UP failed to transfer token");
            }
        }

        emit FollowerSend(
            msg.sender,
            follower,
            _campaigns[msg.sender].assetAddress,
            _campaigns[msg.sender].amount
        );

        return "";
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual returns (bool) {
        return interfaceID == 0xa245bbda;
    }

    function _isUniversalProfile(address account) internal view returns (bool) {
        UniversalProfile up = UniversalProfile(account);
        try up.supportsInterface(0x24871b3d) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    function _registerReceiverDelegate() internal {
        UniversalProfile up = UniversalProfile(msg.sender);
        try
            up.setData(RECEIVER_DELEGATE_KEY, abi.encodePacked(address(this)))
        {} catch Error(string memory reason) {
            revert(
                string(
                    abi.encodePacked(
                        "Failed to set universalReceiverDelegate: ",
                        reason
                    )
                )
            );
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
