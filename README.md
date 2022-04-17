[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-c66648af7eb3fe8bc4f294546bfd86ef473780cde1dea487d3c4ff354943c9ae.svg)](https://classroom.github.com/online_ide?assignment_repo_id=7647008&assignment_repo_type=AssignmentRepo)
# 初识 Cadence - Cadence开发最佳实践

## 编程题

- Q: 使用标准 NFT 接口实现改造 entity

修改 `contracts/Entity.cdc` 合约，使 `Entity` 兼容并实现 Flow 标准 `NonFungibleToken` 接口。  
即 `Element` 实现为标准 NFT，`Collection` 实现为标准 NFT Collection。  
注：原 `withdraw` 方法可修改为 `withdrawByHex`

## 挑战题

继续改造 `Entity` ：

1. 实现 `MetadataViews` 的 `Resolver` `ResolverCollection` 等相关接口。
2. 实现诸如 NFT 铸造、转移、销毁等交易脚本。
