#!/bin/bash
# ============================================
#  TG Bot D1 - 全自动部署脚本
#  一键完成：登录 → 建库 → 配置 → 部署 → 设置 Webhook
# ============================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     🤖 TG Bot D1  v4.0 自动部署脚本     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ---- 1. 检查/安装 wrangler ----
if ! command -v wrangler &> /dev/null; then
    info "正在安装 wrangler..."
    npm install -g wrangler 2>/dev/null || {
        err "npm 安装失败，请手动安装: npm install -g wrangler"
        exit 1
    }
    ok "wrangler 安装完成"
else
    ok "wrangler 已安装 ($(wrangler --version 2>/dev/null | head -1))"
fi

# ---- 2. 登录 Cloudflare ----
info "检查 Cloudflare 登录状态..."
if ! wrangler whoami &> /dev/null; then
    info "请在浏览器中完成登录..."
    wrangler login
fi
ACCOUNT_INFO=$(wrangler whoami 2>&1)
ok "已登录"
echo "$ACCOUNT_INFO"
echo ""

# ---- 3. 收集用户输入 ----
echo "╔══════════════════════════════════════════╗"
echo "║           📝 请输入配置信息               ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Bot Token
while true; do
    read -rp "🔑 Bot Token (从 @BotFather 获取): " BOT_TOKEN
    [[ -n "$BOT_TOKEN" ]] && break
    err "不能为空"
done

# Admin ID
while true; do
    read -rp "👤 你的 Telegram ID (从 @raw_data_bot 获取): " ADMIN_ID
    [[ "$ADMIN_ID" =~ ^[0-9]+$ ]] && break
    err "请输入纯数字 ID"
done

# Group ID
while true; do
    read -rp "👥 管理群组 ID (必须 -100 开头): " GROUP_ID
    [[ "$GROUP_ID" =~ ^-100[0-9]+$ ]] && break
    err "格式错误，必须以 -100 开头的数字"
done

# Worker 名称
read -rp "📦 Worker 名称 (默认 tg-contact-bot): " WORKER_NAME
WORKER_NAME=${WORKER_NAME:-tg-contact-bot}

# Webhook Secret
WEBHOOK_SECRET=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)

echo ""
info "配置确认:"
echo "  Bot Token:    ${BOT_TOKEN:0:10}..."
echo "  管理员 ID:    $ADMIN_ID"
echo "  群组 ID:      $GROUP_ID"
echo "  Worker 名称:  $WORKER_NAME"
echo ""
read -rp "确认并开始部署？(y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && { warn "已取消"; exit 0; }

# ---- 4. 创建 D1 数据库 ----
echo ""
info "📦 创建 D1 数据库..."

# 检查是否已存在
EXISTING_DB=$(wrangler d1 list 2>/dev/null | grep "tg-bot-db" || true)
if [[ -n "$EXISTING_DB" ]]; then
    warn "数据库 tg-bot-db 已存在，尝试获取 ID..."
    DB_ID=$(wrangler d1 list 2>/dev/null | grep "tg-bot-db" | awk -F'│' '{print $3}' | tr -d ' ')
else
    DB_OUTPUT=$(wrangler d1 create tg-bot-db 2>&1)
    DB_ID=$(echo "$DB_OUTPUT" | grep -oP '(?<=database_id = ")[^"]+' || true)
    if [[ -z "$DB_ID" ]]; then
        DB_ID=$(echo "$DB_OUTPUT" | grep -oP "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" || true)
    fi
fi

if [[ -z "$DB_ID" ]]; then
    err "无法自动获取 database_id"
    read -rp "请手动输入 D1 database_id: " DB_ID
fi
ok "D1 数据库 ID: $DB_ID"

# ---- 5. 更新 wrangler.toml ----
info "📝 更新 wrangler.toml..."
cat > wrangler.toml << EOF
name = "${WORKER_NAME}"
main = "TG_Bot_D1.js"
compatibility_date = "2024-09-23"

# D1 数据库绑定
[[d1_databases]]
binding = "TG_BOT_DB"
database_name = "tg-bot-db"
database_id = "${DB_ID}"

# 非敏感变量
[vars]
ADMIN_IDS = "${ADMIN_ID}"
ADMIN_GROUP_ID = "${GROUP_ID}"
EOF
ok "wrangler.toml 已更新"

# ---- 6. 设置 Secret 变量 ----
info "🔐 设置加密环境变量..."
echo "$BOT_TOKEN" | wrangler secret put BOT_TOKEN --name "$WORKER_NAME" 2>/dev/null && ok "BOT_TOKEN ✓" || warn "BOT_TOKEN 设置失败，请手动设置"
echo "$WEBHOOK_SECRET" | wrangler secret put TELEGRAM_WEBHOOK_SECRET --name "$WORKER_NAME" 2>/dev/null && ok "TELEGRAM_WEBHOOK_SECRET ✓" || warn "WEBHOOK_SECRET 设置失败，请手动设置"

# 可选变量
echo ""
read -rp "🛡️ 是否配置 Turnstile 验证？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -rp "   Turnstile Site Key: " TS_KEY
    read -rp "   Turnstile Secret Key: " TS_SECRET
    echo "$TS_KEY" | wrangler secret put TURNSTILE_SITE_KEY --name "$WORKER_NAME" 2>/dev/null && ok "TURNSTILE_SITE_KEY ✓"
    echo "$TS_SECRET" | wrangler secret put TURNSTILE_SECRET_KEY --name "$WORKER_NAME" 2>/dev/null && ok "TURNSTILE_SECRET_KEY ✓"
    # 设置 worker url
    read -rp "   Worker URL (如 https://xxx.workers.dev): " WORKER_URL
    if [[ -n "$WORKER_URL" ]]; then
        echo "$WORKER_URL" | wrangler secret put WORKER_URL --name "$WORKER_NAME" 2>/dev/null && ok "WORKER_URL ✓"
    fi
else
    info "跳过 Turnstile 配置（后续可在 Dashboard 中添加）"
fi

# ---- 7. 部署 ----
echo ""
info "🚀 部署 Worker..."
wrangler deploy --name "$WORKER_NAME" 2>&1 | tail -5
ok "部署完成！"

# 获取 Worker URL
CF_ACCOUNT=$(wrangler whoami 2>/dev/null | grep -oP '(?<=Account ID: )\S+' || echo "")
if [[ -z "$CF_ACCOUNT" ]]; then
    CF_ACCOUNT=$(wrangler whoami 2>/dev/null | grep -oP '[0-9a-f]{32}' | head -1 || echo "")
fi
DEPLOYED_URL="https://${WORKER_NAME}.workers.dev"

# ---- 8. 设置 Webhook ----
echo ""
info "🔗 设置 Telegram Webhook..."
WEBHOOK_URL="https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=${DEPLOYED_URL}&secret_token=${WEBHOOK_SECRET}&allowed_updates=%5B%22message%22,%22edited_message%22,%22callback_query%22,%22message_reaction%22%5D"
RESULT=$(curl -s "$WEBHOOK_URL" 2>&1)
if echo "$RESULT" | grep -q '"ok":true'; then
    ok "Webhook 设置成功！"
else
    warn "Webhook 设置可能失败，请手动访问："
    echo "  $WEBHOOK_URL"
fi

# ---- 9. 完成 ----
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║            ✅ 部署完成！                  ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  🌐 Worker URL:  $DEPLOYED_URL"
echo "  📦 D1 数据库:   tg-bot-db ($DB_ID)"
echo "  🔑 Webhook:     已设置"
echo ""
echo "  📌 接下来："
echo "     1. 向你的 Bot 发送 /start 开始使用"
echo "     2. 在管理群组中发送 /start 打开控制面板"
echo "     3. 如需自定义域名，在 Cloudflare Dashboard 中配置"
echo ""
echo "  📖 文档: https://github.com/Rude56/TG_Bot_D1"
echo ""
