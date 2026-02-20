#!/bin/bash

# 1. 环境准备：获取脚本所在绝对路径
WORK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$WORK_DIR" || exit

# 定义 Docker 命令：如果当前用户不在 docker 组，则自动使用 sudo
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
    COMPOSE_CMD="docker-compose"
else
    DOCKER_CMD="sudo docker"
    COMPOSE_CMD="sudo docker-compose"
    echo "⚠️ 检测到权限不足，将尝试使用 sudo 执行 Docker 命令..."
fi

# 2. 获取原始 IP
echo "🔍 正在检测服务器原始 IP..."
SERVER_IP=$(curl -s --max-time 5 http://ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    echo "❌ 无法连接外网，请检查网络。"
    exit 1
fi
echo "📍 服务器原始 IP: $SERVER_IP"

# # 3. 确保配置存在
# cat << 'EOF' > docker-compose.yml
# services:
#   warp:
#     image: caomingjun/warp
#     container_name: opencode-warp
#     restart: always
#     privileged: true
#     cap_add:
#       - NET_ADMIN
#     # 映射 SOCKS5 到本地 HTTP 代理端口
#     ports:
#       - "127.0.0.1:8118:1080"
#     environment:
#       - WARP_SLEEP=2
# EOF

# 4. 强制重启容器
echo "🔥 正在刷新 WARP 隧道..."
$COMPOSE_CMD down --volumes --remove-orphans > /dev/null 2>&1
$COMPOSE_CMD up -d || { echo "❌ Docker 启动失败！"; exit 1; }

# 5. 等待隧道建立 (WARP 启动需要时间同步密钥)
echo "⏳ 等待 WARP 初始化 (15s)..."
sleep 15

# 6. 多重验证逻辑
echo "🔍 正在验证代理链路 (Max 45s)..."
SUCCESS=false
PROXY_URL="http://127.0.0.1:8118"

for i in {1..9}; do
    # 使用 Cloudflare 官方接口测试
    CURRENT_IP=$(curl -s --max-time 8 --proxy "$PROXY_URL" https://cloudflare.com/cdn-cgi/trace | grep "ip=" | cut -d= -f2)
    
    if [ ! -z "$CURRENT_IP" ] && [ "$CURRENT_IP" != "$SERVER_IP" ]; then
        SUCCESS=true
        break
    fi
    echo "  [尝试 $i/9] 隧道连接中... (当前状态: ${CURRENT_IP:-等待响应/直连})"
    sleep 5
done

# 7. 结果反馈
if [ "$SUCCESS" = true ]; then
    echo "------------------------------------------------"
    echo "✅ 匿名环境已就绪！"
    echo "🌐 匿名出口 IP : $CURRENT_IP"
    echo "------------------------------------------------"
    PROXY_CMD="export http_proxy=$PROXY_URL https_proxy=$PROXY_URL ALL_PROXY=$PROXY_URL"
    echo "👉 请执行下方命令开启代理："
    echo ""
    echo "$PROXY_CMD"
    echo ""
    echo "curl -sl http://ifconfig.me"
    echo ""
else
    echo "------------------------------------------------"
    echo "❌ 错误: 代理未能成功切换 IP。"
    echo "📜 容器日志摘要："
    $DOCKER_CMD logs --tail 20 opencode-warp
    echo "------------------------------------------------"
    exit 1
fi