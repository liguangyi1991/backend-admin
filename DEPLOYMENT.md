# Backend Admin 部署文档

## 部署脚本说明

本项目提供了完整的自动化部署脚本，包含以下文件：

### 脚本文件
- `scripts/setup-server.sh` - 服务器环境安装脚本
- `scripts/deploy.sh` - 项目部署脚本  
- `scripts/manage.sh` - 服务管理脚本
- `scripts/nginx.conf` - Nginx 配置文件
- `scripts/nginx-ssl.conf` - HTTPS Nginx 配置文件

## 部署步骤

### 1. 准备服务器环境
```bash
# 上传并运行环境安装脚本
sudo chmod +x scripts/setup-server.sh
sudo ./scripts/setup-server.sh
```

### 2. 部署项目
```bash
# 在项目根目录运行部署脚本
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### 3. 配置 Nginx（可选）
```bash
# 使用 IP 访问
sudo ./scripts/manage.sh setup-nginx

# 使用域名访问
sudo ./scripts/manage.sh setup-nginx your-domain.com
```

## 服务管理

使用管理脚本进行日常维护：

```bash
# 赋予执行权限
chmod +x scripts/manage.sh

# 查看服务状态
./scripts/manage.sh status

# 查看日志
./scripts/manage.sh logs

# 重启服务
./scripts/manage.sh restart

# 健康检查
./scripts/manage.sh health

# 备份数据
./scripts/manage.sh backup

# 更新服务
./scripts/manage.sh update

# 系统清理
./scripts/manage.sh cleanup

# 监控服务
./scripts/manage.sh monitor
```

## 手动部署（不使用脚本）

如果需要手动部署：

### 1. 安装依赖
```bash
# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. 上传项目文件
```bash
# 方式1：使用 git
git clone <your-repo-url>
cd backend-admin

# 方式2：直接上传
# 将项目文件上传到服务器
```

### 3. 配置环境变量
```bash
# 修改 docker-compose.yml 中的密码
# 或创建 .env.production 文件
```

### 4. 启动服务
```bash
docker-compose build
docker-compose up -d
```

## SSL 证书配置

### 使用 Let's Encrypt
```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加：0 12 * * * /usr/bin/certbot renew --quiet
```

### 使用自定义证书
```bash
# 将证书放置到指定位置
sudo cp your-domain.crt /etc/ssl/certs/
sudo cp your-domain.key /etc/ssl/private/

# 使用 SSL 配置
sudo cp scripts/nginx-ssl.conf /etc/nginx/sites-available/backend-admin
sudo ln -s /etc/nginx/sites-available/backend-admin /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## 监控和维护

### 查看日志
```bash
# 应用日志
docker-compose logs -f backend

# 数据库日志  
docker-compose logs -f mysql

# Nginx 日志
tail -f /var/log/nginx/backend-admin.access.log
tail -f /var/log/nginx/backend-admin.error.log
```

### 备份和恢复
```bash
# 自动备份（使用管理脚本）
./scripts/manage.sh backup

# 手动备份数据库
docker-compose exec mysql mysqldump -u admin -p backend_admin > backup.sql

# 恢复数据库
docker-compose exec -i mysql mysql -u admin -p backend_admin < backup.sql
```

### 更新应用
```bash
# 自动更新（使用管理脚本）
./scripts/manage.sh update

# 手动更新
git pull
docker-compose build --no-cache
docker-compose up -d
```

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   sudo netstat -tlnp | grep :3000
   # 修改 docker-compose.yml 中的端口映射
   ```

2. **数据库连接失败**
   ```bash
   # 检查数据库容器状态
   docker-compose ps mysql
   # 查看数据库日志
   docker-compose logs mysql
   ```

3. **构建失败**
   ```bash
   # 清理 Docker 缓存
   docker system prune -a
   # 重新构建
   docker-compose build --no-cache
   ```

4. **内存不足**
   ```bash
   # 检查系统资源
   free -h
   df -h
   # 清理系统
   ./scripts/manage.sh cleanup
   ```

### 性能优化

1. **数据库优化**
   - 调整 MySQL 配置
   - 添加数据库索引
   - 配置连接池

2. **应用优化**
   - 启用 Gzip 压缩
   - 配置缓存
   - 优化静态资源

3. **服务器优化**
   - 调整系统参数
   - 配置防火墙
   - 设置监控告警

## 安全建议

1. **更改默认密码**
   - 修改数据库密码
   - 使用强 JWT 密钥
   - 定期更换密钥

2. **网络安全**
   - 配置防火墙规则
   - 使用 HTTPS
   - 限制访问来源

3. **系统安全**
   - 定期更新系统
   - 禁用不必要的服务
   - 配置日志审计