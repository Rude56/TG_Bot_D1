# TG Bot D1

<div align="center">
  <img src="https://img.shields.io/badge/TG%20Bot-D1-blue?logo=telegram" alt="Telegram">
  <img src="https://img.shields.io/badge/Cloudflare-Worker-orange?logo=cloudflare" alt="Cloudflare">
  <img src="https://img.shields.io/badge/Version-4.0-green" alt="Version">
  <img src="https://img.shields.io/github/license/Rude56/TG_Bot_D1" alt="License">
</div>

---

基于 [TG_Chat_Bot-D1](https://github.com/Rude56/TG_Chat_Bot-D1) v3.85 改造的 Telegram 双向机器人，通过 Cloudflare Worker + D1 数据库构建。

## ✨ 特性

- 🔄 **双向消息转发**：私聊 ↔ 管理群组话题
- 👥 **群管理员自动识别**：群内所有管理员自动拥有操作权限，无需手动配置
- 🔗 **转发来源保留**：用户转发的消息在管理端显示原始来源
- 🛡️ **安全验证**：Cloudflare Turnstile / Google reCAPTCHA / Q&A 提问
- 🚫 **风控系统**：屏蔽词、频率限制、自动封禁
- 🌙 **就寝模式**：定时自动休眠回复
- 📝 **用户资料卡**：头像、ID、用户名、备注
- 🗑️ **双向撤回**：引用消息发送 `/del` 即可
- 💬 **引用同步**：双向引用关系保持
- ✏️ **编辑同步**：消息修改实时同步

## 📖 使用

### 用户端
- `/start` — 开始验证或进入对话
- `/del` — 引用消息后发送，双向撤回

### 管理员端
- `/start` — 打开管理控制面板（仅主管理员）
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

## 🚀 部署

### 方式一：一键脚本 【推荐】

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Rude56/TG_Bot_D1/main/setup.sh)
```

自动完成：安装 wrangler → 登录 → 创建 D1 → 配置变量 → 部署 → 设置 Webhook。

### 方式二：Wrangler CLI 手动部署

```bash
# 安装 wrangler
npm install -g wrangler

# 登录
wrangler login

# 创建 D1 数据库
wrangler d1 create tg-bot-db
# 记下 database_id，填入 wrangler.toml

# 编辑 wrangler.toml（填入你的配置）

# 设置敏感变量
wrangler secret put BOT_TOKEN
wrangler secret put TELEGRAM_WEBHOOK_SECRET

# 部署
wrangler deploy

# 设置 Webhook
curl "https://api.telegram.org/bot<TOKEN>/setWebhook?url=<WORKER_URL>&secret_token=<SECRET>&allowed_updates=[\"message\",\"edited_message\",\"callback_query\",\"message_reaction\"]"
```

### 方式三：Cloudflare Dashboard 手动部署

1. **创建 D1 数据库**：Dashboard → 存储和数据库 → D1 → 创建 `tg-bot-db`
2. **创建 Worker**：Workers 和 Pages → 创建 Worker → 命名 → 部署
3. **粘贴代码**：将 `TG_Bot_D1.js` 全量覆盖默认代码
4. **绑定 D1**：设置 → 绑定 → 添加 D1 绑定，变量名 `TG_BOT_DB`
5. **添加变量**（设置 → 变量）：

   | 变量 | 说明 | 必填 |
   |------|------|:---:|
   | `BOT_TOKEN` | Bot Token | ✅ |
   | `ADMIN_IDS` | 管理员 ID（逗号分隔） | ✅ |
   | `ADMIN_GROUP_ID` | 管理群组 ID（`-100` 开头） | ✅ |
   | `TELEGRAM_WEBHOOK_SECRET` | 自定义随机字符串 | ✅ |
   | `WORKER_URL` | Worker 完整 URL | ⬜ |
   | `TURNSTILE_SITE_KEY` | Turnstile 站点密钥 | ⬜ |
   | `TURNSTILE_SECRET_KEY` | Turnstile 密钥 | ⬜ |

6. **设置 Webhook**（浏览器访问）：
   ```
   https://api.telegram.org/bot<TOKEN>/setWebhook?url=<WORKER_URL>&secret_token=<SECRET>&allowed_updates=["message","edited_message","callback_query","message_reaction"]
   ```

### 环境变量说明

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `BOT_TOKEN` | Telegram Bot Token | 必填 |
| `ADMIN_IDS` | 主管理员 ID（逗号分隔） | 必填 |
| `ADMIN_GROUP_ID` | 管理群组 ID（超级群组，`-100` 开头） | 必填 |
| `TELEGRAM_WEBHOOK_SECRET` | Webhook 验证密钥 | 必填 |
| `WORKER_URL` | Worker 完整 URL（无末尾斜杠） | 可选 |
| `TURNSTILE_SITE_KEY` | Cloudflare Turnstile 站点密钥 | 可选 |
| `TURNSTILE_SECRET_KEY` | Cloudflare Turnstile 密钥 | 可选 |
| `RECAPTCHA_SITE_KEY` | Google reCAPTCHA v2 站点密钥 | 可选 |
| `RECAPTCHA_SECRET_KEY` | Google reCAPTCHA v2 密钥 | 可选 |

## 🔧 v3.85 → v4.0 变更

| 项目 | 原版 | 改造后 |
|------|------|--------|
| 协管管理 | 手动添加协管 ID | **自动识别群管理员** |
| 转发消息 | `copyMessage`（无来源） | **`forwardMessage`**（保留来源） |
| 部署方式 | 手动复制粘贴 | **一键脚本 / wrangler** |

## ❓ 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 系统忙，请稍后再试 | 群组未升级超级群组 / 未开启话题 | 检查群组设置 |
| /start 无反应 | BOT_TOKEN 错误 | 重新获取 Token，检查变量 |
| 回复消息无反应 | ADMIN_IDS 错误 | 通过 @raw_data_bot 确认 ID |
| 点击菜单 ERROR | D1 未绑定 | 检查绑定变量名 `TG_BOT_DB` |

## 📄 许可证

[MIT License](LICENSE)
