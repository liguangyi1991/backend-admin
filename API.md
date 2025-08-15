# 后台管理系统 API 文档

## 启动项目

```bash
# 安装依赖
npm install

# 启动开发环境
npm run start:dev

# 启动生产环境
npm run start

# 构建项目
npm run build
```

## API 接口

### 用户注册
- **接口**: `POST /auth/register`
- **请求体**:
```json
{
  "username": "admin",
  "email": "admin@example.com", 
  "password": "123456"
}
```

### 用户登录
- **接口**: `POST /auth/login`
- **请求体**:
```json
{
  "username": "admin",
  "password": "123456"
}
```
- **响应**:
```json
{
  "access_token": "jwt_token_here",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com"
  }
}
```

### 获取用户信息
- **接口**: `GET /auth/profile`
- **请求头**: `Authorization: Bearer <access_token>`
- **响应**:
```json
{
  "userId": 1,
  "username": "admin"
}
```

## 测试示例

### 1. 注册用户
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","email":"admin@example.com","password":"123456"}'
```

### 2. 用户登录
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}'
```

### 3. 获取用户信息（需要替换实际的token）
```bash
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

## 技术栈

- **框架**: NestJS
- **认证**: JWT + Passport
- **密码加密**: bcryptjs
- **数据验证**: class-validator + class-transformer

## 注意事项

1. 当前使用内存存储用户数据，重启后数据会丢失
2. JWT密钥设置为固定值，生产环境需要使用环境变量
3. 可以根据需要添加数据库支持（如 PostgreSQL, MySQL, MongoDB）