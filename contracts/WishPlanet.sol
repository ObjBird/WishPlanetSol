// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WishPlanet
 * @dev 心愿星球智能合约 - 简化版本，每个地址可以存储和获取uint256数据
 */
contract WishPlanet {
    // 存储每个地址的愿望数据（uint256）
    mapping(address => bytes) public userWish;

    // 存储所有有愿望的地址
    address[] public wishAddresses;

    // 记录地址是否已经创建过愿望
    mapping(address => bool) public hasWish;

    // 点赞相关状态变量
    mapping(address => uint256) public wishLikes; // 每个地址的愿望获得的点赞数
    mapping(address => mapping(address => bool)) public hasLiked; // 用户是否已对某个愿望点赞

    // 打赏相关状态变量
    mapping(address => uint256) public wishTotalRewards; // 每个愿望收到的总打赏金额
    mapping(address => mapping(address => uint256)) public userRewards; // 用户对某个愿望的打赏金额

    // 费用设置
    uint256 public baseLikeFee = 100000000000000000; // 基础点赞费用 (0.1 MON in wei)
    address public owner; // 合约所有者，用于提取手续费

    // 事件
    event WishCreated(address indexed user, bytes wishData);
    event WishUpdated(
        address indexed user,
        bytes oldWishData,
        bytes newWishData
    );
    event WishLiked(
        address indexed liker,
        address indexed wishOwner,
        uint256 multiplier,
        uint256 fee,
        uint256 newTotalLikes
    );
    event WishRewarded(
        address indexed rewarder,
        address indexed wishOwner,
        uint256 amount,
        uint256 newTotalRewards
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev 创建或更新愿望
     * @param _wishData 愿望数据（uint256）
     */
    function createWish(bytes memory _wishData) external {
        bool isNewWish = !hasWish[msg.sender];
        bytes memory oldWishData = userWish[msg.sender];

        userWish[msg.sender] = _wishData;

        if (isNewWish) {
            hasWish[msg.sender] = true;
            wishAddresses.push(msg.sender);
            emit WishCreated(msg.sender, _wishData);
        } else {
            emit WishUpdated(msg.sender, oldWishData, _wishData);
        }
    }

    /**
     * @dev 获取单个地址的愿望数据
     * @param _user 用户地址
     * @return 愿望数据
     */
    function getSingleWish(address _user) external view returns (bytes memory) {
        return userWish[_user];
    }

    /**
     * @dev 获取所有愿望数据
     * @return addresses 所有有愿望的地址数组
     * @return wishes 对应的愿望数据数组
     */
    function getAllWishes()
        external
        view
        returns (address[] memory addresses, bytes[] memory wishes)
    {
        uint256 length = wishAddresses.length;
        addresses = new address[](length);
        wishes = new bytes[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = wishAddresses[i];
            wishes[i] = userWish[wishAddresses[i]];
        }

        return (addresses, wishes);
    }

    /**
     * @dev 获取愿望总数
     * @return 愿望总数
     */
    function getTotalWishCount() external view returns (uint256) {
        return wishAddresses.length;
    }

    /**
     * @dev 检查地址是否有愿望
     * @param _user 用户地址
     * @return 是否有愿望
     */
    function checkHasWish(address _user) external view returns (bool) {
        return hasWish[_user];
    }

    /**
     * @dev 点赞愿望（支持倍率）
     * @param _wishOwner 愿望所有者地址
     * @param _multiplier 点赞倍率（1-10倍）
     */
    function likeWish(
        address _wishOwner,
        uint256 _multiplier
    ) external payable {
        require(hasWish[_wishOwner], "Target address has no wish");
        require(_wishOwner != msg.sender, "Cannot like your own wish");
        require(
            !hasLiked[msg.sender][_wishOwner],
            "You have already liked this wish"
        );
        require(
            _multiplier >= 1 && _multiplier <= 10,
            "Multiplier must be between 1 and 10"
        );

        uint256 requiredFee = baseLikeFee * _multiplier;
        require(msg.value >= requiredFee, "Insufficient fee");

        // 标记用户已点赞
        hasLiked[msg.sender][_wishOwner] = true;
        // 增加点赞数（每次点赞+1，倍率只影响费用）
        wishLikes[_wishOwner] += 1;

        // 如果支付了多余的费用，退还给用户
        if (msg.value > requiredFee) {
            payable(msg.sender).transfer(msg.value - requiredFee);
        }

        emit WishLiked(
            msg.sender,
            _wishOwner,
            _multiplier,
            requiredFee,
            wishLikes[_wishOwner]
        );
    }

    /**
     * @dev 获取愿望的点赞数
     * @param _user 用户地址
     * @return 点赞数
     */
    function getLikes(address _user) external view returns (uint256) {
        return wishLikes[_user];
    }

    /**
     * @dev 检查用户是否已对某个愿望点赞
     * @param _liker 点赞者地址
     * @param _wishOwner 愿望所有者地址
     * @return 是否已点赞
     */
    function checkHasLiked(
        address _liker,
        address _wishOwner
    ) external view returns (bool) {
        return hasLiked[_liker][_wishOwner];
    }

    /**
     * @dev 计算点赞费用
     * @param _multiplier 倍率
     * @return 所需费用
     */
    function calculateLikeFee(
        uint256 _multiplier
    ) external view returns (uint256) {
        require(
            _multiplier >= 1 && _multiplier <= 10,
            "Multiplier must be between 1 and 10"
        );
        return baseLikeFee * _multiplier;
    }

    /**
     * @dev 设置基础点赞费用（仅所有者）
     * @param _newFee 新的基础费用
     */
    function setBaseLikeFee(uint256 _newFee) external onlyOwner {
        baseLikeFee = _newFee;
    }

    /**
     * @dev 提取合约中的手续费（仅所有者）
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner).transfer(balance);
    }

    /**
     * @dev 获取合约余额
     * @return 合约余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev 为愿望打赏
     * @param _wishOwner 愿望所有者地址
     */
    function rewardWish(address _wishOwner) external payable {
        require(hasWish[_wishOwner], "Target address has no wish");
        require(_wishOwner != msg.sender, "Cannot reward your own wish");
        require(msg.value > 0, "Reward amount must be greater than 0");

        // 更新打赏记录
        wishTotalRewards[_wishOwner] += msg.value;
        userRewards[msg.sender][_wishOwner] += msg.value;

        // 直接转账给愿望所有者（不收取手续费）
        payable(_wishOwner).transfer(msg.value);

        emit WishRewarded(
            msg.sender,
            _wishOwner,
            msg.value,
            wishTotalRewards[_wishOwner]
        );
    }

    /**
     * @dev 获取愿望的总打赏金额
     * @param _user 用户地址
     * @return 总打赏金额
     */
    function getTotalRewards(address _user) external view returns (uint256) {
        return wishTotalRewards[_user];
    }

    /**
     * @dev 获取用户对某个愿望的打赏金额
     * @param _rewarder 打赏者地址
     * @param _wishOwner 愿望所有者地址
     * @return 打赏金额
     */
    function getUserRewardAmount(
        address _rewarder,
        address _wishOwner
    ) external view returns (uint256) {
        return userRewards[_rewarder][_wishOwner];
    }
}
