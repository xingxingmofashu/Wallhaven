# 隐私政策

**最后更新：2025 年 6 月 18 日**

## 简介

Wallhaven 是一款由个人开发者提供的开源 iOS 客户端，用于浏览 [wallhaven.cc](https://wallhaven.cc) 上的壁纸。本隐私政策说明本应用如何收集、使用和保护您的信息。

## 信息收集与使用

### 本地存储的数据

本应用将以下数据存储在您的设备本地，**不会上传到任何第三方服务器**（wallhaven.cc 官方 API 调用除外）：

| 数据类型 | 存储位置 | 用途 |
|---|---|---|
| Wallhaven API 密钥 | `UserDefaults` | 调用 Wallhaven API 时认证身份 |
| 外观偏好设置 | `UserDefaults` | 记住您的浅色/深色主题选择 |
| 收藏的壁纸 | SwiftData（本地 SQLite） | 保存您标记的壁纸 |
| 收藏集数据 | SwiftData（本地 SQLite） | 管理您的自定义收藏集 |

### Wallhaven API

本应用通过 Wallhaven 官方 API 获取壁纸数据。当您使用搜索、浏览等功能时，应用会将您的请求发送至 wallhaven.cc 的服务器。这些请求可能包含：

- 您的搜索关键词和筛选条件
- 您的 API 密钥（如果您已配置）
- 标准 HTTP 请求信息（IP 地址、User-Agent 等）

以上数据由 Wallhaven 按照其自身的隐私政策处理。建议您查阅 [Wallhaven 隐私政策](https://wallhaven.cc/privacy) 了解更多信息。

### 不会收集的信息

本应用**不会**：

- 收集个人身份信息（姓名、电子邮件、电话号码等）
- 使用第三方分析工具或跟踪器
- 上传您的壁纸、收藏集或其他本地数据到任何服务器
- 记录您的使用行为或浏览历史
- 展示个性化广告

## 数据安全

所有本地数据仅存储在您的设备上，系统会自动保护这些数据不被其他应用访问。API 密钥存储在 `UserDefaults` 中，仅在本应用内使用。

## 第三方服务

本应用仅与 wallhaven.cc 官方 API 进行通信，不集成任何第三方 SDK、分析工具或广告服务。

## 数据删除

您可以通过以下方式删除本应用存储的所有数据：

1. 在应用设置中清除图片缓存
2. 在 iOS 设置中卸载本应用（将删除所有本地数据）

## 开源

本应用是开源项目，您可以在 [GitHub](https://github.com/xingxingmofashu/Wallhaven) 查看完整源代码，验证隐私声明的真实性。

## 政策更新

本隐私政策可能不时更新。更新后会在此页面公布，并标注新的生效日期。

## 联系方式

如有任何问题或疑虑，请通过 GitHub Issues 与我们联系：

[https://github.com/xingxingmofashu/Wallhaven/issues](https://github.com/xingxingmofashu/Wallhaven/issues)
