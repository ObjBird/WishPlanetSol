# WishPlanet 心愿星球智能合约

## 功能概述

WishPlanet是一个基于区块链的心愿星球智能合约，用户可以：

- 🌟 **创建愿望**：在星球上任意位置创建愿望
- 👍 **点赞愿望**：为其他用户的愿望点赞
- 💰 **打赏愿望**：用加密货币打赏喜欢的愿望
- 🏆 **查看排行榜**：按点赞数或打赏金额查看热门愿望

## 合约核心功能

### 1. 愿望管理
- `createWish(content, latitude, longitude)` - 创建新愿望
- `getWish(wishId)` - 获取愿望详情
- `deactivateWish(wishId)` - 停用愿望

### 2. 互动功能
- `likeWish(wishId)` - 点赞愿望
- `rewardWish(wishId)` - 打赏愿望（需要发送ETH）
- `hasUserLiked(wishId, user)` - 检查用户是否已点赞

### 3. 排行榜
- `getTopWishesByLikes(limit)` - 按点赞数排序的前N个愿望
- `getTopWishesByRewards(limit)` - 按打赏金额排序的前N个愿望
- `getBatchWishInfo(wishIds)` - 批量获取愿望信息

### 4. 统计信息
- `getContractStats()` - 获取合约统计信息
- `getAllActiveWishIds()` - 获取所有活跃愿望ID

## 部署到 Monad Testnet

### 前置条件

1. 安装依赖：
```bash
npm install
```

2. 创建 `.env` 文件：
```bash
MNEMONIC=your twelve word mnemonic phrase goes here
```

3. 获取测试网代币：
   - 访问 [Monad Testnet Faucet](https://faucet.monad.xyz/)
   - 输入你的钱包地址获取测试代币

### 部署步骤

1. 编译合约：
```bash
npx truffle compile
```

2. 部署到 Monad Testnet：
```bash
npx truffle migrate --network monad_testnet
```

3. 验证部署：
```bash
npx truffle console --network monad_testnet
```

在控制台中测试：
```javascript
// 获取合约实例
const instance = await WishPlanet.deployed()

// 创建一个测试愿望
await instance.createWish("希望世界和平", 39500000, 116400000) // 北京坐标

// 获取愿望详情
const wish = await instance.getWish(1)
console.log(wish)

// 查看合约统计
const stats = await instance.getContractStats()
console.log(stats)
```

## 合约地址记录

部署成功后，请记录以下信息：

- **网络**: Monad Testnet
- **合约地址**: `[待部署后填写]`
- **部署者地址**: `[待部署后填写]`
- **交易哈希**: `[待部署后填写]`

## 前端集成示例

### Web3.js 示例

```javascript
// 连接到合约
const contract = new web3.eth.Contract(WishPlanetABI, contractAddress);

// 创建愿望
await contract.methods.createWish("我的愿望", latitude * 1000000, longitude * 1000000)
  .send({ from: userAddress });

// 点赞愿望
await contract.methods.likeWish(wishId).send({ from: userAddress });

// 打赏愿望
await contract.methods.rewardWish(wishId)
  .send({ from: userAddress, value: web3.utils.toWei("0.1", "ether") });

// 获取排行榜
const topWishes = await contract.methods.getTopWishesByLikes(10).call();
```

## 安全特性

- ✅ 防止重复点赞
- ✅ 不能给自己的愿望点赞/打赏
- ✅ 内容长度验证（1-500字符）
- ✅ 坐标范围验证
- ✅ 平台手续费机制（5%）
- ✅ 愿望停用功能

## Gas 费用优化

- 使用 `view` 函数减少查询成本
- 批量操作函数减少交易次数
- 高效的排序算法
- 合理的数据结构设计

## 注意事项

1. **坐标格式**：纬度和经度需要乘以1,000,000存储（避免小数点）
2. **手续费**：打赏时会收取5%的平台手续费
3. **Gas限制**：在Monad测试网上有足够的Gas限制
4. **测试网代币**：仅用于测试，无实际价值

## 联系信息

如有问题或建议，请联系开发团队。
