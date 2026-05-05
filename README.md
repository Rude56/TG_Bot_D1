# TG Bot D1 v4.0

基于 [TG_Chat_Bot-D1](https://github.com/Rude56/TG_Chat_Bot-D1) v3.85 改造的 Telegram 双向机器人。

## ✨ 改动说明

### v3.85 → v4.0 变更

| 项目 | 原版 | 改造后 |
|------|------|--------|
| 协管管理 | 手动添加协管 ID | **自动识别群管理员**（通过 `getChatAdministrators` API） |
| 转发消息 | `copyMessage`（无来源） | **`forwardMessage`**（保留原始发送者信息） |
| 普通消息 | `copyMessage` | `copyMessage`（不变） |
| 欢迎语/自动回复 | `sendMessage` | `sendMessage`（无引用，不变） |
| 部署方式 | 手动复制粘贴 | **`wrangler.toml` 一键部署** |
| 环境变量 | 9 个（含 reCAPTCHA） | **7 个**（reCAPTCHA 可选） |

### 核心特性

- 🔄 **双向消息转发**：私聊 ↔ 管理群话题
- 👥 **群管理员自动识别**：群内所有管理员自动拥有操作权限，无需手动配置
- 🔗 **转发来源保留**：用户转发的消息在管理端显示原始来源
- 🛡️ **安全验证**：Cloudflare Turnstile / Google reCAPTCHA / Q&A 提问
- 🚫 **风控系统**：屏蔽词、频率限制、自动封禁
- 🌙 **就寝模式**：定时自动休眠回复
- 📝 **用户资料卡**：头像、ID、用户名、备注
- 🗑️ **双向撤回**：引用消息发送 `/del` 即可

## 🚀 部署

### 前置要求

- [Cloudflare 账号](https://dash.cloudflare.com/)
- Telegram Bot Token（[@BotFather](https://t.me/BotFather)）
- 管理员群组 ID（开启话题的超级群组，`-100` 开头）
- 你的 Telegram ID

### 方式一：Wrangler CLI（推荐）

```bash
# 1. 安装 wrangler
npm install -g wrangler

# 2. 登录
wrangler login

# 3. 创建 D1 数据库
wrangler d1 create tg-bot-db
# 记下输出的 database_id，填入 wrangler.toml

# 4. 编辑 wrangler.toml
# 填入 database_id、BOT_TOKEN、ADMIN_IDS、ADMIN_GROUP_ID 等

# 5. 设置敏感变量（推荐用 secret）
wrangler secret put BOT_TOKEN
wrangler secret put TURNSTILE_SECRET_KEY
wrangler secret put RECAPTCHA_SECRET_KEY
wrangler secret put TELEGRAM_WEBHOOK_SECRET

# 6. 部署
wrangler deploy
```

### 方式二：Dashboard 手动部署

1. **创建 D1 数据库**：Cloudflare Dashboard → 存储和数据库 → D1 → 创建 `tg-bot-db`

2. **创建 Worker**：Workers 和 Pages → 创建 Worker → 命名 → 部署

3. **粘贴代码**：将 `TG_Bot_D1.js` 全量覆盖默认代码

4. **绑定 D1**：设置 → 绑定 → 添加 D1 数据库绑定，变量名 `TG_BOT_DB`

5. **添加环境变量**（设置 → 变量）：

   | 变量 | 说明 |
   |------|------|
   | `BOT_TOKEN` | Bot Token |
   | `ADMIN_IDS` | 管理员 ID（逗号分隔） |
   | `ADMIN_GROUP_ID` | 管理群组 ID（`-100` 开头） |
   | `WORKER_URL` | Worker 完整 URL（无末尾斜杠） |
   | `TURNSTILE_SITE_KEY` | Turnstile 站点密钥 |
   | `TURNSTILE_SECRET_KEY` | Turnstile 密钥 |
   | `TELEGRAM_WEBHOOK_SECRET` | 自定义随机字符串 |

6. **创建 Turnstile**（可选）：Cloudflare → Turnstile → 添加站点

7. **设置 Webhook**（浏览器访问）：
   ```
   https://api.telegram.org/bot<TOKEN>/setWebhook?url=<WORKER_URL>&secret_token=<WEBHOOK_SECRET>&allowed_updates=["message","edited_message","callback_query","message_reaction"]
   ```

### 方式三：一键脚本

```bash
chmod +x deploy.sh
./deploy.sh
```

## 📖 使用

### 用户端
- `/start` — 开始验证或进入对话
- `/del` — 引用消息后发送，双向撤回

### 管理员端（群内所有管理员自动获得权限）
- `/start` — 打开管理控制面板
- `/help` — 查看帮助
- `/reset <id>` — 重置用户验证（仅主管理员）

## 🔧 管理员权限说明

| 权限 | 主管理员（ADMIN_IDS） | 群管理员（自动识别） |
|------|:---:|:---:|
| 打开控制面板 | ✅ | ❌ |
| 修改配置 | ✅ | ❌ |
| 屏蔽/解封用户 | ✅ | ✅ |
| 删除话题 | ✅ | ✅ |
| 回复用户消息 | ✅ | ✅ |
| 添加备注 | ✅ | ✅ |
| 重置验证 | ✅ | ❌ |

## 📄 许可证

[MIT License](LICENSE)
