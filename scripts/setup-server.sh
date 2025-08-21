#!/bin/bash

# 服务器环境安装脚本
# 支持 Ubuntu/Debian 系统

set -e

echo "🚀 开始配置服务器环境..."

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用 sudo 运行此脚本"
    exit 1
fi

# 更新系统包
echo "📦 更新系统包..."
apt update && apt upgrade -y

# 安装基础工具
echo "🛠️ 安装基础工具..."
apt install -y curl wget git vim htop ufw

# 安装 Docker
echo "🐳 安装 Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # 将当前用户添加到 docker 组
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        echo "✅ 用户 $SUDO_USER 已添加到 docker 组"
    fi
else
    echo "✅ Docker 已安装"
fi

# 安装 Docker Compose
echo "🐙 安装 Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION="v2.24.0"
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
else
    echo "✅ Docker Compose 已安装"
fi

# 安装 Nginx
echo "🌐 安装 Nginx..."
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    systemctl enable nginx
else
    echo "✅ Nginx 已安装"
fi

# 配置防火墙
echo "🔥 配置防火墙..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 3000
echo "✅ 防火墙配置完成"

# 创建部署目录
DEPLOY_DIR="/opt/backend-admin"
echo "📁 创建部署目录: $DEPLOY_DIR"
mkdir -p $DEPLOY_DIR
if [ -n "$SUDO_USER" ]; then
    chown -R $SUDO_USER:$SUDO_USER $DEPLOY_DIR
fi

# 启动服务
systemctl start docker
systemctl start nginx

echo "✅ 服务器环境配置完成!"
echo "📍 部署目录: $DEPLOY_DIR"
echo "🔄 请重新登录或运行 'newgrp docker' 以使 docker 组权限生效"
echo ""
echo "📋 下一步："
echo "1. 将项目代码上传到 $DEPLOY_DIR"
echo "2. 运行 deploy.sh 脚本部署项目"