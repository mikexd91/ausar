// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoyaltyApp is ERC721URIStorage, ERC20, Ownable {
    // NFT token name and symbol
    string private constant _name = "LoyaltyNFT";
    string private constant _symbol = "LOYALTY";
    
    struct Reward {
        string name;
        uint256 tokenAmount;
        string description;
    }
    
    // Array to store all the available rewards
    Reward[] private rewards;
    
    // Mapping to keep track of user's balances
    mapping(address => uint256) private balances;
    
    // Mapping to keep track of reward token's burned status
    mapping(address => bool) private isTokenBurned;
    
    // Flag to determine if the reward token is transferable or not
    bool private isTokenTransferable;

    constructor() ERC721(_name, _symbol) ERC20(_name, _symbol) {}

    /**
     * @dev Function to mint a new NFT or transfer tokens to the user.
     * @param to The address of the user who will receive the NFT or tokens.
     * @param uri The URI of the NFT's metadata.
     * @param tokenAmount The amount of tokens to be transferred.
     */
    function mint(
        address to,
        string memory uri,
        uint256 tokenAmount
    ) external onlyOwner {
        if (bytes(uri).length > 0) {
            // Mint a new NFT to the user
            uint256 tokenId = totalSupply();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
        }
        
        if (tokenAmount > 0) {
            // Transfer tokens to the user
            _mint(to, tokenAmount);
            balances[to] += tokenAmount;
        }
    }
    
    /**
     * @dev Function to redeem a reward by burning the reward token.
     * @param tokenId The ID of the reward token to be burned.
     */
    function redeemReward(uint256 tokenId) external {
        require(_exists(tokenId), "Invalid token ID");
        require(isTokenTransferable, "Reward token is not transferable");
        require(!_isApprovedOrOwner(_msgSender(), tokenId), "Caller is token owner");

        // Burn the reward token
        _burn(tokenId);
        isTokenBurned[_msgSender()] = true;
        
        uint256 rewardIndex = tokenId - 1; // Token ID starts from 1
        require(rewardIndex < rewards.length, "Invalid reward index");
        Reward memory reward = rewards[rewardIndex];
        
        // Transfer the reward token amount to the caller
        _transfer(_msgSender(), reward.tokenAmount);
        
        // Reduce the user's balance by the reward token amount
        require(balances[_msgSender()] >= reward.tokenAmount, "Insufficient token balance");
        balances[_msgSender()] -= reward.tokenAmount;
    }
    
    /**
     * @dev Function to add a new reward to the loyalty program.
     * @param name The name of the reward.
     * @param tokenAmount The amount of reward tokens.
     * @param description The description of the reward.
     */
    function addReward(
        string memory name,
        uint256 tokenAmount,
        string memory description
    ) external onlyOwner {
        // Create a new reward object
        Reward memory newReward = Reward({
            name: name,
            tokenAmount: tokenAmount,
            description: description
        });
        
        // Add the reward to the rewards array
        rewards.push(newReward);
    }
    
    /**
     * @dev Function to get the details of a reward.
     * @param rewardIndex The index of the reward in the rewards array.
     * @return name The name of the reward.
     * @return tokenAmount The amount of reward tokens.
     * @return description The description of the reward.
     */
    function getReward(uint256 rewardIndex)
        external
        view
        returns (string memory name, uint256 tokenAmount, string memory description)
    {
        require(rewardIndex < rewards.length, "Invalid reward index");
        
        Reward memory reward = rewards[rewardIndex];
        return (reward.name, reward.tokenAmount, reward.description);
    }
    
    /**
     * @dev Function to set the reward token transferability.
     * @param transferable Flag to determine if the reward token is transferable or not.
     */
    function setTokenTransferability(bool transferable) external onlyOwner {
        isTokenTransferable = transferable;
    }
    
    /**
     * @dev Function to check if a reward token is burned.
     * @param tokenOwner The address of the reward token owner.
     * @return True if the token is burned, False otherwise.
     */
    function isRewardTokenBurned(address tokenOwner) external view returns (bool) {
        return isTokenBurned[tokenOwner];
    }
    
    /**
     * @dev Function to get the user's token balance.
     * @param user The address of the user.
     * @return The token balance of the user.
     */
    function getTokenBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}