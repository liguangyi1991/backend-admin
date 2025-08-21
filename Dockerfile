# 使用官方 Node.js 运行时作为基础镜像
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装所有依赖（构建需要 devDependencies）
RUN npm i && npm cache clean --force

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM node:20-alpine AS production

# 安装 dumb-init 用于正确处理信号
RUN apk add --no-cache dumb-init

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

# 设置工作目录
WORKDIR /app


# 复制 package.json 文件
COPY --chown=nestjs:nodejs package*.json ./

# 只安装生产依赖
RUN npm i --only=production && npm cache clean --force

# 从构建阶段复制构建结果
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist

# 切换到非 root 用户
USER nestjs

# 暴露端口
EXPOSE 3000

# 设置环境变量
ENV NODE_ENV=production

# 启动应用
CMD ["dumb-init", "node", "dist/main"]