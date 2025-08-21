#!/bin/bash

# 服务管理脚本
# 用于管理 Backend Admin 服务

set -e

PROJECT_NAME="backend-admin"
DEPLOY_DIR="/opt/$PROJECT_NAME"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 检查部署目录
check_deploy_dir() {
    if [ ! -d "$DEPLOY_DIR" ] || [ ! -f "$DEPLOY_DIR/docker-compose.yml" ]; then
        print_error "项目未部署或部署目录不存在: $DEPLOY_DIR"
        exit 1
    fi
}

# 显示服务状态
status() {
    print_message "显示服务状态..."
    cd $DEPLOY_DIR
    docker-compose ps
    echo ""
    print_message "容器资源使用情况:"
    docker stats --no-stream $(docker-compose ps -q) 2>/dev/null || echo "没有运行的容器"
}

# 启动服务
start() {
    print_message "启动服务..."
    cd $DEPLOY_DIR
    docker-compose up -d
    sleep 5
    status
}

# 停止服务
stop() {
    print_message "停止服务..."
    cd $DEPLOY_DIR
    docker-compose down
    print_message "服务已停止"
}

# 重启服务
restart() {
    print_message "重启服务..."
    stop
    sleep 3
    start
}

# 查看日志
logs() {
    local service=${1:-backend}
    local lines=${2:-100}
    
    print_message "查看 $service 服务日志 (最近 $lines 行)..."
    cd $DEPLOY_DIR
    
    if [ "$service" = "all" ]; then
        docker-compose logs --tail=$lines -f
    else
        docker-compose logs --tail=$lines -f $service
    fi
}

# 更新服务
update() {
    print_message "更新服务..."
    cd $DEPLOY_DIR
    
    # 拉取最新代码（如果是 git 仓库）
    if [ -d ".git" ]; then
        print_message "拉取最新代码..."
        git pull
    fi
    
    # 重新构建并启动
    docker-compose build --no-cache
    docker-compose down
    docker-compose up -d
    
    print_message "服务更新完成"
    status
}

# 健康检查
health() {
    print_message "执行健康检查..."
    
    # 检查容器状态
    cd $DEPLOY_DIR
    local unhealthy_containers=$(docker-compose ps --format "table {{.Name}}\t{{.Status}}" | grep -v "Up" | tail -n +2)
    
    if [ -n "$unhealthy_containers" ]; then
        print_error "发现异常容器:"
        echo "$unhealthy_containers"
    else
        print_message "✅ 所有容器运行正常"
    fi
    
    # 检查应用健康状态
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        print_message "✅ 应用健康检查通过"
    else
        print_error "❌ 应用健康检查失败"
    fi
    
    # 检查端口
    if netstat -tlnp | grep -q ":3000 "; then
        print_message "✅ 端口 3000 正在监听"
    else
        print_error "❌ 端口 3000 未监听"
    fi
}

# 备份数据
backup() {
    local backup_dir="/opt/backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    print_message "创建数据备份..."
    mkdir -p $backup_dir
    
    cd $DEPLOY_DIR
    
    # 备份 MySQL 数据
    if docker-compose ps mysql | grep -q "Up"; then
        print_message "备份 MySQL 数据..."
        docker-compose exec -T mysql mysqldump -u admin -p$(grep DATABASE_PASSWORD docker-compose.yml | cut -d'=' -f2) backend_admin > "$backup_dir/mysql_backup_$timestamp.sql"
        print_message "MySQL 备份完成: $backup_dir/mysql_backup_$timestamp.sql"
    fi
    
    # 备份配置文件
    tar -czf "$backup_dir/config_backup_$timestamp.tar.gz" .env.production docker-compose.yml
    print_message "配置备份完成: $backup_dir/config_backup_$timestamp.tar.gz"
    
    # 清理旧备份（保留最近7天）
    find $backup_dir -name "*.sql" -mtime +7 -delete 2>/dev/null || true
    find $backup_dir -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    
    print_message "✅ 备份完成"
}

# 清理系统
cleanup() {
    print_message "清理系统资源..."
    
    # 清理未使用的 Docker 镜像
    docker image prune -f
    
    # 清理未使用的 Docker 卷
    docker volume prune -f
    
    # 清理未使用的 Docker 网络
    docker network prune -f
    
    print_message "✅ 系统清理完成"
}

# 配置 Nginx
setup_nginx() {
    local domain=${1:-""}
    
    if [ -z "$domain" ]; then
        print_warning "使用默认配置（IP 访问）"
        cp scripts/nginx.conf /etc/nginx/sites-available/backend-admin
    else
        print_message "配置域名: $domain"
        sed "s/your-domain.com/$domain/g" scripts/nginx.conf > /etc/nginx/sites-available/backend-admin
    fi
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/backend-admin /etc/nginx/sites-enabled/
    
    # 移除默认站点
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    nginx -t
    
    # 重启 Nginx
    systemctl restart nginx
    
    print_message "✅ Nginx 配置完成"
}

# 监控服务
monitor() {
    print_message "启动服务监控..."
    
    while true; do
        clear
        echo "=== Backend Admin 服务监控 ==="
        echo "时间: $(date)"
        echo ""
        
        # 系统负载
        echo "系统负载:"
        uptime
        echo ""
        
        # 内存使用
        echo "内存使用:"
        free -h
        echo ""
        
        # 磁盘使用
        echo "磁盘使用:"
        df -h | grep -E "/$|/opt"
        echo ""
        
        # 服务状态
        echo "服务状态:"
        cd $DEPLOY_DIR
        docker-compose ps
        echo ""
        
        # 容器资源
        echo "容器资源:"
        docker stats --no-stream $(docker-compose ps -q) 2>/dev/null | head -5
        echo ""
        
        echo "按 Ctrl+C 退出监控"
        sleep 10
    done
}

# 显示帮助
usage() {
    echo "Backend Admin 服务管理脚本"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "可用命令:"
    echo "  status          显示服务状态"
    echo "  start           启动服务"
    echo "  stop            停止服务"
    echo "  restart         重启服务"
    echo "  logs [service]  查看日志 (默认: backend, 可选: mysql, all)"
    echo "  update          更新服务"
    echo "  health          健康检查"
    echo "  backup          备份数据"
    echo "  cleanup         清理系统资源"
    echo "  setup-nginx [domain]  配置 Nginx (可选域名)"
    echo "  monitor         监控服务状态"
    echo ""
    echo "示例:"
    echo "  $0 status                    # 查看状态"
    echo "  $0 logs                      # 查看后端日志"
    echo "  $0 logs mysql               # 查看数据库日志"
    echo "  $0 logs all                 # 查看所有日志"
    echo "  $0 setup-nginx example.com  # 配置域名"
}

# 主函数
main() {
    case "${1:-}" in
        status)
            check_deploy_dir
            status
            ;;
        start)
            check_deploy_dir
            start
            ;;
        stop)
            check_deploy_dir
            stop
            ;;
        restart)
            check_deploy_dir
            restart
            ;;
        logs)
            check_deploy_dir
            logs "$2" "$3"
            ;;
        update)
            check_deploy_dir
            update
            ;;
        health)
            check_deploy_dir
            health
            ;;
        backup)
            check_deploy_dir
            backup
            ;;
        cleanup)
            cleanup
            ;;
        setup-nginx)
            setup_nginx "$2"
            ;;
        monitor)
            check_deploy_dir
            monitor
            ;;
        help|--help|-h)
            usage
            ;;
        "")
            usage
            exit 1
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"