// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WishPlanet
 * @dev 心愿星球智能合约 - 用户可以在星球上创建愿望、点赞、打赏
 */
contract WishPlanet {
    // 愿望结构体
    struct Wish {
        uint256 id;              // 愿望ID
        address creator;         // 创建者地址
        string content;          // 愿望内容
        int256 latitude;         // 纬度（放大1000000倍存储，避免小数）
        int256 longitude;        // 经度（放大1000000倍存储，避免小数）
        uint256 likes;           // 点赞数
        uint256 totalReward;     // 总打赏金额
        uint256 createdAt;       // 创建时间
        bool isActive;           // 是否激活
    }
    
    // 状态变量
    mapping(uint256 => Wish) public wishes;
    mapping(uint256 => mapping(address => bool)) public hasLiked; // 防止重复点赞
    mapping(uint256 => mapping(address => uint256)) public userRewards; // 用户对愿望的打赏记录
    
    uint256 public wishCounter = 0;
    uint256 public constant MIN_CONTENT_LENGTH = 1;
    uint256 public constant MAX_CONTENT_LENGTH = 500;
    
    address public owner;
    uint256 public platformFeePercent = 5; // 平台手续费 5%
    
    // 事件
    event WishCreated(uint256 indexed wishId, address indexed creator, string content, int256 latitude, int256 longitude);
    event WishLiked(uint256 indexed wishId, address indexed liker, uint256 newLikeCount);
    event WishRewarded(uint256 indexed wishId, address indexed rewarder, uint256 amount, uint256 newTotalReward);
    event WishDeactivated(uint256 indexed wishId);
    
    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validWishId(uint256 _wishId) {
        require(_wishId > 0 && _wishId <= wishCounter, "Invalid wish ID");
        require(wishes[_wishId].isActive, "Wish is not active");
        _;
    }
    
    modifier validContent(string memory _content) {
        bytes memory contentBytes = bytes(_content);
        require(contentBytes.length >= MIN_CONTENT_LENGTH && contentBytes.length <= MAX_CONTENT_LENGTH, 
                "Content length must be between 1 and 500 characters");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev 创建新愿望
     * @param _content 愿望内容
     * @param _latitude 纬度（放大1000000倍）
     * @param _longitude 经度（放大1000000倍）
     */
    function createWish(
        string memory _content, 
        int256 _latitude, 
        int256 _longitude
    ) external validContent(_content) {
        // 验证坐标范围
        require(_latitude >= -90000000 && _latitude <= 90000000, "Invalid latitude");
        require(_longitude >= -180000000 && _longitude <= 180000000, "Invalid longitude");
        
        wishCounter++;
        
        wishes[wishCounter] = Wish({
            id: wishCounter,
            creator: msg.sender,
            content: _content,
            latitude: _latitude,
            longitude: _longitude,
            likes: 0,
            totalReward: 0,
            createdAt: block.timestamp,
            isActive: true
        });
        
        emit WishCreated(wishCounter, msg.sender, _content, _latitude, _longitude);
    }
    
    /**
     * @dev 点赞愿望
     * @param _wishId 愿望ID
     */
    function likeWish(uint256 _wishId) external validWishId(_wishId) {
        require(!hasLiked[_wishId][msg.sender], "You have already liked this wish");
        require(wishes[_wishId].creator != msg.sender, "Cannot like your own wish");
        
        hasLiked[_wishId][msg.sender] = true;
        wishes[_wishId].likes++;
        
        emit WishLiked(_wishId, msg.sender, wishes[_wishId].likes);
    }
    
    /**
     * @dev 打赏愿望
     * @param _wishId 愿望ID
     */
    function rewardWish(uint256 _wishId) external payable validWishId(_wishId) {
        require(msg.value > 0, "Reward amount must be greater than 0");
        require(wishes[_wishId].creator != msg.sender, "Cannot reward your own wish");
        
        uint256 platformFee = (msg.value * platformFeePercent) / 100;
        uint256 creatorReward = msg.value - platformFee;
        
        // 更新记录
        userRewards[_wishId][msg.sender] += msg.value;
        wishes[_wishId].totalReward += msg.value;
        
        // 转账给愿望创建者
        payable(wishes[_wishId].creator).transfer(creatorReward);
        
        emit WishRewarded(_wishId, msg.sender, msg.value, wishes[_wishId].totalReward);
    }
    
    /**
     * @dev 获取愿望详情
     * @param _wishId 愿望ID
     */
    function getWish(uint256 _wishId) external view validWishId(_wishId) returns (
        uint256 id,
        address creator,
        string memory content,
        int256 latitude,
        int256 longitude,
        uint256 likes,
        uint256 totalReward,
        uint256 createdAt
    ) {
        Wish memory wish = wishes[_wishId];
        return (
            wish.id,
            wish.creator,
            wish.content,
            wish.latitude,
            wish.longitude,
            wish.likes,
            wish.totalReward,
            wish.createdAt
        );
    }
    
    /**
     * @dev 获取所有活跃愿望的ID列表
     */
    function getAllActiveWishIds() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // 先计算活跃愿望数量
        for (uint256 i = 1; i <= wishCounter; i++) {
            if (wishes[i].isActive) {
                activeCount++;
            }
        }
        
        // 创建数组并填充
        uint256[] memory activeWishIds = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= wishCounter; i++) {
            if (wishes[i].isActive) {
                activeWishIds[index] = i;
                index++;
            }
        }
        
        return activeWishIds;
    }
    
    /**
     * @dev 获取按点赞数排序的前N个愿望ID
     * @param _limit 返回数量限制
     */
    function getTopWishesByLikes(uint256 _limit) external view returns (uint256[] memory) {
        uint256[] memory allWishIds = this.getAllActiveWishIds();
        return _sortWishesByLikes(allWishIds, _limit);
    }
    
    /**
     * @dev 获取按打赏金额排序的前N个愿望ID
     * @param _limit 返回数量限制
     */
    function getTopWishesByRewards(uint256 _limit) external view returns (uint256[] memory) {
        uint256[] memory allWishIds = this.getAllActiveWishIds();
        return _sortWishesByRewards(allWishIds, _limit);
    }
    
    /**
     * @dev 批量获取愿望信息（用于排行榜）
     * @param _wishIds 愿望ID数组
     */
    function getBatchWishInfo(uint256[] memory _wishIds) external view returns (
        uint256[] memory ids,
        string[] memory contents,
        uint256[] memory likes,
        uint256[] memory totalRewards,
        address[] memory creators
    ) {
        uint256 length = _wishIds.length;
        ids = new uint256[](length);
        contents = new string[](length);
        likes = new uint256[](length);
        totalRewards = new uint256[](length);
        creators = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 wishId = _wishIds[i];
            if (wishId > 0 && wishId <= wishCounter && wishes[wishId].isActive) {
                Wish memory wish = wishes[wishId];
                ids[i] = wish.id;
                contents[i] = wish.content;
                likes[i] = wish.likes;
                totalRewards[i] = wish.totalReward;
                creators[i] = wish.creator;
            }
        }
    }
    
    /**
     * @dev 检查用户是否已点赞某个愿望
     */
    function hasUserLiked(uint256 _wishId, address _user) external view returns (bool) {
        return hasLiked[_wishId][_user];
    }
    
    /**
     * @dev 获取用户对某个愿望的打赏总额
     */
    function getUserRewardAmount(uint256 _wishId, address _user) external view returns (uint256) {
        return userRewards[_wishId][_user];
    }
    
    /**
     * @dev 停用愿望（仅创建者或合约拥有者）
     */
    function deactivateWish(uint256 _wishId) external validWishId(_wishId) {
        require(
            msg.sender == wishes[_wishId].creator || msg.sender == owner,
            "Only wish creator or contract owner can deactivate"
        );
        
        wishes[_wishId].isActive = false;
        emit WishDeactivated(_wishId);
    }
    
    /**
     * @dev 设置平台手续费（仅合约拥有者）
     */
    function setPlatformFeePercent(uint256 _feePercent) external onlyOwner {
        require(_feePercent <= 10, "Fee cannot exceed 10%");
        platformFeePercent = _feePercent;
    }
    
    /**
     * @dev 提取平台手续费（仅合约拥有者）
     */
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner).transfer(balance);
    }
    
    /**
     * @dev 获取合约基本统计信息
     */
    function getContractStats() external view returns (
        uint256 totalWishes,
        uint256 activeWishes,
        uint256 totalLikes,
        uint256 totalRewards
    ) {
        totalWishes = wishCounter;
        activeWishes = 0;
        totalLikes = 0;
        totalRewards = 0;
        
        for (uint256 i = 1; i <= wishCounter; i++) {
            if (wishes[i].isActive) {
                activeWishes++;
                totalLikes += wishes[i].likes;
                totalRewards += wishes[i].totalReward;
            }
        }
    }
    
    // 内部函数：按点赞数排序
    function _sortWishesByLikes(uint256[] memory _wishIds, uint256 _limit) internal view returns (uint256[] memory) {
        uint256 length = _wishIds.length;
        if (length == 0) return new uint256[](0);
        
        // 简单的冒泡排序（适用于小数据集）
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                if (wishes[_wishIds[j]].likes < wishes[_wishIds[j + 1]].likes) {
                    uint256 temp = _wishIds[j];
                    _wishIds[j] = _wishIds[j + 1];
                    _wishIds[j + 1] = temp;
                }
            }
        }
        
        // 返回前_limit个
        uint256 resultLength = length > _limit ? _limit : length;
        uint256[] memory result = new uint256[](resultLength);
        for (uint256 i = 0; i < resultLength; i++) {
            result[i] = _wishIds[i];
        }
        
        return result;
    }
    
    // 内部函数：按打赏金额排序
    function _sortWishesByRewards(uint256[] memory _wishIds, uint256 _limit) internal view returns (uint256[] memory) {
        uint256 length = _wishIds.length;
        if (length == 0) return new uint256[](0);
        
        // 简单的冒泡排序（适用于小数据集）
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                if (wishes[_wishIds[j]].totalReward < wishes[_wishIds[j + 1]].totalReward) {
                    uint256 temp = _wishIds[j];
                    _wishIds[j] = _wishIds[j + 1];
                    _wishIds[j + 1] = temp;
                }
            }
        }
        
        // 返回前_limit个
        uint256 resultLength = length > _limit ? _limit : length;
        uint256[] memory result = new uint256[](resultLength);
        for (uint256 i = 0; i < resultLength; i++) {
            result[i] = _wishIds[i];
        }
        
        return result;
    }
}
