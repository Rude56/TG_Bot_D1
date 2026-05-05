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

## 🚀 一键部署

### 1. 点击部署

[![Deploy to Cloudflare Workers](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/Rude56/TG_Bot_D1)

点击按钮 → 授权 Cloudflare → 自动创建 Worker 并部署。

### 2. 创建 D1 数据库

进入 [Cloudflare Dashboard](https://dash.cloudflare.com/) → **存储和数据库** → **D1** → 创建数据库，名称 `tg-bot-db`。

### 3. 绑定 D1

进入刚创建的 Worker → **设置** → **绑定** → **添加** → **D1 数据库**：
- 变量名称：`TG_BOT_DB`
- 数据库：选择 `tg-bot-db`

### 4. 添加环境变量

进入 Worker → **设置** → **变量和机密** → **添加变量**：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `BOT_TOKEN` | `12345:AAH...` | Bot Token（建议加密） |
| `ADMIN_IDS` | `123456789` | 你的 Telegram ID |
| `ADMIN_GROUP_ID` | `-100123456789` | 管理群组 ID |

> 敏感变量（BOT_TOKEN）建议勾选「加密」。

### 5. 设置 Webhook

部署完成后，在浏览器访问（替换 `<TOKEN>` 和 `<WORKER_URL>`）：

```
https://api.telegram.org/bot<TOKEN>/setWebhook?url=<WORKER_URL>&allowed_updates=["message","edited_message","callback_query","message_reaction"]
```

### 6. 开始使用

向 Bot 发送 `/start` → 在管理群组发送 `/start` 打开控制面板。

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
| 部署方式 | 手动复制粘贴 | **一键按钮** |
| 环境变量 | 9 个 | **3 个**（BOT_TOKEN / ADMIN_IDS / ADMIN_GROUP_ID） |
| WEBHOOK_SECRET | 必填 | **自动跳过**（可选） |
| WORKER_URL | 必填 | **自动检测** |

## ❓ 常见问题

| 问题 | 解决 |
|------|------|
| 系统忙，请稍后再试 | 检查群组是否为超级群组并开启话题 |
| /start 无反应 | 检查 BOT_TOKEN 是否正确 |
| 回复消息无反应 | 检查 ADMIN_IDS 是否正确 |
| 点击菜单 ERROR | 检查 D1 绑定变量名是否为 `TG_BOT_DB` |

## 📄 许可证

[MIT License](LICENSE)
