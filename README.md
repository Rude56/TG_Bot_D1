# TG Bot D1

<div align="center">
  <img src="https://img.shields.io/badge/TG%20Bot-D1-blue?logo=telegram" alt="Telegram">
  <img src="https://img.shields.io/badge/Cloudflare-Worker-orange?logo=cloudflare" alt="Cloudflare">
  <img src="https://img.shields.io/badge/Version-4.0-green" alt="Version">
  <img src="https://img.shields.io/github/license/Rude56/TG_Bot_D1" alt="License">
</div>

---

基于 Cloudflare Worker + D1 数据库构建的 Telegram 双向机器人。

## ✨ 特性

- 🔄 **双向消息转发**：私聊 ↔ 管理群组话题
- 👥 **群管理员自动识别**：群内所有管理员自动拥有操作权限
- 🔗 **转发来源保留**：用户转发的消息在管理端显示原始来源
- 🛡️ **安全验证**：Cloudflare Turnstile / Google reCAPTCHA / Q&A
- 🚫 **风控系统**：屏蔽词、频率限制、自动封禁
- 🌙 **就寝模式**：定时自动休眠回复
- 📝 **用户资料卡**：头像、ID、用户名、备注
- 🗑️ **双向撤回**：引用消息发送 `/del` 即可
- 💬 **引用 / 编辑同步**：双向引用关系与编辑实时同步

## 🚀 部署

### 方式一：一键部署 【推荐】

[![Deploy to Cloudflare Workers](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/Rude56/TG_Bot_D1)

点击按钮 → 授权 Cloudflare → 自动创建 Worker 并部署，然后继续下面的配置步骤。

### 方式二：Fork + Connect to Git

1. 点击右上角 **Fork** 按钮
2. Cloudflare Dashboard → Workers 和 Pages → **创建** → **连接到 Git** → 选择你的 Fork
3. 保存并部署

---

### 配置步骤（两种方式通用）

#### 1. 创建 D1 数据库

进入 [Cloudflare Dashboard](https://dash.cloudflare.com/) → **存储和数据库** → **D1** → 创建数据库，名称 `tg-bot-db`。

#### 2. 绑定 D1

进入 Worker → **设置** → **绑定** → **添加** → **D1 数据库**：
- 变量名称：`TG_BOT_DB`
- 数据库：选择 `tg-bot-db`

#### 3. 添加环境变量

进入 Worker → **设置** → **变量和机密** → **添加变量**：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `BOT_TOKEN` | `12345:AAH...` | 从 @BotFather 获取（建议勾选「加密」） |
| `ADMIN_IDS` | `123456789` | 你的 Telegram ID（从 @raw_data_bot 获取） |
| `ADMIN_GROUP_ID` | `-100123456789` | 管理群组 ID（必须开启话题的超级群组） |

#### 4. 设置 Webhook

在浏览器访问（替换 `<TOKEN>` 和 `<WORKER_URL>`）：

```
https://api.telegram.org/bot<TOKEN>/setWebhook?url=<WORKER_URL>&allowed_updates=["message","edited_message","callback_query","message_reaction"]
```

> `<WORKER_URL>` 在 Worker 概览页可以看到，类似 `https://xxx.workers.dev`

返回 `{"ok":true,"result":true}` 即成功。

#### 5. 开始使用

1. 向 Bot 发送 `/start` 完成验证
2. 在管理群组中向 Bot 发送 `/start` 打开控制面板

---

## 📖 使用

### 用户端
- `/start` — 开始验证或进入对话
- `/del` — 引用消息后发送，双向撤回

### 管理员端
- `/start` — 打开控制面板（仅主管理员）
- `/help` — 查看帮助
- `/reset <id>` — 重置用户验证（仅主管理员）

| 权限 | 主管理员 | 群管理员（自动） |
|------|:---:|:---:|
| 控制面板 / 修改配置 | ✅ | ❌ |
| 屏蔽 / 解封用户 | ✅ | ✅ |
| 删除话题 | ✅ | ✅ |
| 回复用户消息 | ✅ | ✅ |
| 添加备注 | ✅ | ✅ |
| 重置验证 | ✅ | ❌ |

## 🔧 v3.85 → v4.0 变更

| 项目 | 原版 | 改造后 |
|------|------|--------|
| 协管管理 | 手动添加协管 ID | **自动识别群管理员** |
| 转发消息 | `copyMessage`（无来源） | **`forwardMessage`**（保留来源） |
| 部署方式 | 手动复制粘贴 | **一键按钮 / Fork** |
| 环境变量 | 9 个 | **3 个** |

## ❓ 常见问题

| 问题 | 解决 |
|------|------|
| 系统忙，请稍后再试 | 检查群组是否为超级群组并开启话题 |
| /start 无反应 | 检查 BOT_TOKEN 是否正确 |
| 回复消息无反应 | 检查 ADMIN_IDS 是否正确 |
| 点击菜单 ERROR | 检查 D1 绑定变量名是否为 `TG_BOT_DB` |

## 📄 许可证

[MIT License](LICENSE)
