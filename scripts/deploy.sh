#!/bin/bash

# 项目部署脚本
# 部署 Backend Admin 到生产服务器

set -e

PROJECT_NAME="backend-admin"
DEPLOY_DIR="/opt/$PROJECT_NAME"
BACKUP_DIR="/opt/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 检查是否在正确的目录
check_project_directory() {
    if [ ! -f "package.json" ] || [ ! -f "docker-compose.yml" ]; then
        print_error "请在项目根目录运行此脚本"
        exit 1
    fi
}

# 创建备份
create_backup() {
    print_message "创建备份..."
    mkdir -p $BACKUP_DIR
    
    if [ -d "$DEPLOY_DIR" ]; then
        tar -czf "$BACKUP_DIR/${PROJECT_NAME}_backup_$TIMESTAMP.tar.gz" -C "$DEPLOY_DIR" . 2>/dev/null || true
        print_message "备份已创建: $BACKUP_DIR/${PROJECT_NAME}_backup_$TIMESTAMP.tar.gz"
    fi
}

# 停止现有服务
stop_services() {
    print_message "停止现有服务..."
    if [ -f "$DEPLOY_DIR/docker-compose.yml" ]; then
        cd $DEPLOY_DIR
        docker-compose down || true
        cd - > /dev/null
    fi
}

# 复制项目文件
deploy_files() {
    print_message "部署项目文件..."
    
    # 创建部署目录
    mkdir -p $DEPLOY_DIR
    
    # 复制项目文件，排除不需要的文件
    rsync -av --delete \
        --exclude 'node_modules' \
        --exclude '.git' \
        --exclude 'dist' \
        --exclude '*.log' \
        --exclude '.env' \
        --exclude '.env.development' \
        --exclude '.env.test' \
        . $DEPLOY_DIR/
    
    print_message "项目文件部署完成"
}

# 配置环境变量
configure_environment() {
    print_message "配置生产环境..."
    
    cd $DEPLOY_DIR
    
    # 生成随机密钥
    JWT_SECRET=$(openssl rand -hex 32)
    DB_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    
    print_warning "请记录以下生成的密码："
    echo "数据库密码: $DB_PASSWORD"
    echo "MySQL Root 密码: $MYSQL_ROOT_PASSWORD"
    echo "JWT 密钥: $JWT_SECRET"
    
    # 创建生产环境配置
    cat > .env.production << EOF
# 生产环境配置 - 自动生成于 $TIMESTAMP
NODE_ENV=production
PORT=3000
APP_NAME=Backend Admin
APP_VERSION=1.0.0

# 数据库配置
DATABASE_HOST=mysql
DATABASE_PORT=3306
DATABASE_USERNAME=admin
DATABASE_PASSWORD=$DB_PASSWORD
DATABASE_NAME=backend_admin

# JWT配置
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=24h

# 日志配置
LOG_LEVEL=info
EOF

    # 更新 docker-compose.yml 中的密码
    sed -i "s/MYSQL_PASSWORD=admin123/MYSQL_PASSWORD=$DB_PASSWORD/g" docker-compose.yml
    sed -i "s/DATABASE_PASSWORD=admin123/DATABASE_PASSWORD=$DB_PASSWORD/g" docker-compose.yml
    sed -i "s/MYSQL_ROOT_PASSWORD=root123/MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD/g" docker-compose.yml
    sed -i "s/JWT_SECRET=your-very-strong-production-secret-key-change-this/JWT_SECRET=$JWT_SECRET/g" docker-compose.yml
    
    print_message "环境配置完成"
}

# 构建和启动服务
start_services() {
    print_message "构建和启动服务..."
    
    cd $DEPLOY_DIR
    
    # 构建并启动服务
    docker-compose build --no-cache
    docker-compose up -d
    
    print_message "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    docker-compose ps
}

# 健康检查
health_check() {
    print_message "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            print_message "✅ 服务健康检查通过"
            return 0
        fi
        
        print_warning "健康检查失败 (尝试 $attempt/$max_attempts)，等待 10 秒后重试..."
        sleep 10
        ((attempt++))
    done
    
    print_error "❌ 服务健康检查失败"
    return 1
}

# 显示部署信息
show_deployment_info() {
    print_message "🎉 部署完成!"
    echo ""
    echo "📋 部署信息："
    echo "  项目目录: $DEPLOY_DIR"
    echo "  访问地址: http://$(curl -s ifconfig.me):3000"
    echo "  本地访问: http://localhost:3000"
    echo ""
    echo "🔧 管理命令："
    echo "  查看日志: cd $DEPLOY_DIR && docker-compose logs -f"
    echo "  重启服务: cd $DEPLOY_DIR && docker-compose restart"
    echo "  停止服务: cd $DEPLOY_DIR && docker-compose down"
    echo ""
    echo "📁 备份位置: $BACKUP_DIR"
}

# 主函数
main() {
    print_message "🚀 开始部署 Backend Admin..."
    
    check_project_directory
    create_backup
    stop_services
    deploy_files
    configure_environment
    start_services
    
    if health_check; then
        show_deployment_info
    else
        print_error "部署可能存在问题，请检查日志"
        echo "查看日志命令: cd $DEPLOY_DIR && docker-compose logs"
        exit 1
    fi
}

# 执行主函数
main "$@"