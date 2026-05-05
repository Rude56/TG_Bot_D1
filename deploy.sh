#!/bin/bash
# TG Bot D1 - 快速部署脚本
# 使用前请确保已安装 wrangler: npm install -g wrangler

set -e

echo "🚀 TG Bot D1 部署脚本"
echo "===================="

# 检查 wrangler
if ! command -v wrangler &> /dev/null; then
    echo "❌ 未安装 wrangler，正在安装..."
    npm install -g wrangler
fi

# 检查登录状态
echo "📋 检查 Cloudflare 登录状态..."
if ! wrangler whoami &> /dev/null; then
    echo "🔐 请登录 Cloudflare..."
    wrangler login
fi

echo ""
echo "📝 请准备以下信息："
echo "  1. Bot Token（从 @BotFather 获取）"
echo "  2. 你的 Telegram ID（从 @raw_data_bot 获取）"
echo "  3. 管理群组 ID（-100 开头，从 @raw_data_bot 获取）"
echo "  4. Worker URL（部署后获得）"
echo ""

read -p "是否继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# 创建 D1 数据库
echo ""
echo "📦 创建 D1 数据库..."
DB_OUTPUT=$(wrangler d1 create tg-bot-db 2>&1) || true
echo "$DB_OUTPUT"

# 提取 database_id
DB_ID=$(echo "$DB_OUTPUT" | grep -oP '(?<=database_id = ")[^"]+' || echo "")
if [ -z "$DB_ID" ]; then
    read -p "请输入 D1 database_id: " DB_ID
fi

# 更新 wrangler.toml
sed -i "s/database_id = \"<YOUR_DATABASE_ID>\"/database_id = \"$DB_ID\"/" wrangler.toml

# 收集环境变量
read -p "Bot Token: " BOT_TOKEN
read -p "管理员 ID: " ADMIN_IDS
read -p "群组 ID: " ADMIN_GROUP_ID
read -p "Webhook Secret（留空自动生成）: " WEBHOOK_SECRET

if [ -z "$WEBHOOK_SECRET" ]; then
    WEBHOOK_SECRET=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
    echo "生成的 Webhook Secret: $WEBHOOK_SECRET"
fi

# 更新 wrangler.toml 中的变量
sed -i "s|<YOUR_BOT_TOKEN>|$BOT_TOKEN|" wrangler.toml
sed -i "s|<YOUR_ADMIN_ID>|$ADMIN_IDS|" wrangler.toml
sed -i "s|<YOUR_GROUP_ID>|$ADMIN_GROUP_ID|" wrangler.toml
sed -i "s|<YOUR_WEBHOOK_SECRET>|$WEBHOOK_SECRET|" wrangler.toml

# 部署
echo ""
echo "🚀 部署 Worker..."
wrangler deploy

# 获取 Worker URL
WORKER_NAME=$(grep 'name = ' wrangler.toml | head -1 | cut -d'"' -f2)
echo ""
echo "✅ 部署完成！"
echo ""
echo "📌 接下来请："
echo "  1. 在浏览器访问以下 URL 设置 Webhook："
echo "     https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=https://${WORKER_NAME}.\$(wrangler whoami 2>/dev/null | grep 'Account' | awk '{print \$2}').workers.dev&secret_token=${WEBHOOK_SECRET}&allowed_updates=[\"message\",\"edited_message\",\"callback_query\",\"message_reaction\"]"
echo ""
echo "  2. 如需 Turnstile 验证，在 Cloudflare Dashboard 创建 Turnstile 站点"
echo ""
echo "  3. 向 Bot 发送 /start 开始使用"
