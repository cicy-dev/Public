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
    COMPOSE_CMD="sudo docker compose"
    echo "⚠️ 检测到权限不足，将尝试使用 sudo 执行 Docker 命令..."
fi

# 2. 获取本地 IP
echo "🔍 正在检测服务器本地 IP..."
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    echo "❌ 无法获取本地 IP。"
    exit 1
fi
echo "📍 服务器本地 IP: $SERVER_IP"

# 3. 强制重启容器
echo "🔥 正在刷新 WARP 隧道..."
$COMPOSE_CMD down --volumes --remove-orphans > /dev/null 2>&1
$COMPOSE_CMD up -d || { echo "❌ Docker 启动失败！"; exit 1; }

# 4. 等待隧道建立 (WARP 启动需要时间同步密钥)
echo "⏳ 等待 WARP 初始化 (15s)..."
sleep 15

# 5. 多重验证逻辑
echo "🔍 正在验证代理链路 (Max 45s)..."
SUCCESS=false
PROXY_URL="http://127.0.0.1:8118"

for i in {1..9}; do
    # 使用 localhost 测试
    CURRENT_IP=$(curl -s --max-time 8 --proxy "$PROXY_URL" http://localhost:8118 2>/dev/null | head -1)
    
    if [ ! -z "$CURRENT_IP" ]; then
        SUCCESS=true
        break
    fi
    echo "  [尝试 $i/9] 隧道连接中..."
    sleep 5
done

# 6. 结果反馈
if [ "$SUCCESS" = true ]; then
    echo "------------------------------------------------"
    echo "✅ 代理已就绪！"
    echo "------------------------------------------------"
    PROXY_CMD="export http_proxy=$PROXY_URL https_proxy=$PROXY_URL ALL_PROXY=$PROXY_URL"
    echo "👉 请执行下方命令开启代理："
    echo ""
    echo "$PROXY_CMD"
    echo ""
    echo "curl -s --noproxy '*' http://localhost:8118"
    echo ""
else
    echo "------------------------------------------------"
    echo "⚠️ 代理启动中，请稍后重试"
    echo "📜 容器日志："
    $DOCKER_CMD logs --tail 10 opencode-warp 2>/dev/null || echo "容器未找到"
    echo "------------------------------------------------"
fi