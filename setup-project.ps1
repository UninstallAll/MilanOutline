# MilanOutline 项目初始化脚本
# PowerShell 脚本用于快速搭建项目结构

Write-Host "🚀 开始初始化 MilanOutline 项目..." -ForegroundColor Green

# 创建项目目录结构
Write-Host "📁 创建项目目录结构..." -ForegroundColor Yellow

$directories = @(
    "frontend/src/components",
    "frontend/src/pages",
    "frontend/src/hooks",
    "frontend/src/store",
    "frontend/src/services",
    "frontend/src/types",
    "frontend/src/utils",
    "frontend/public",
    "backend/src/controllers",
    "backend/src/services",
    "backend/src/models",
    "backend/src/middleware",
    "backend/src/routes",
    "backend/src/utils",
    "backend/src/types",
    "backend/prisma",
    "shared/types",
    "shared/utils",
    "docs",
    "tests/frontend",
    "tests/backend"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  ✓ 创建目录: $dir" -ForegroundColor Gray
}

# 创建前端 package.json
Write-Host "📦 创建前端 package.json..." -ForegroundColor Yellow
$frontendPackageJson = @"
{
  "name": "milan-outline-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "test": "vitest"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0",
    "antd": "^5.12.0",
    "@ant-design/icons": "^5.2.0",
    "zustand": "^4.4.0",
    "@dnd-kit/core": "^6.1.0",
    "@dnd-kit/sortable": "^8.0.0",
    "slate": "^0.101.0",
    "slate-react": "^0.102.0",
    "socket.io-client": "^4.7.0",
    "axios": "^1.6.0",
    "dayjs": "^1.11.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "@vitejs/plugin-react": "^4.0.0",
    "eslint": "^8.45.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.0",
    "typescript": "^5.0.2",
    "vite": "^4.4.0",
    "vitest": "^0.34.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/jest-dom": "^6.0.0"
  }
}
"@

$frontendPackageJson | Out-File -FilePath "frontend/package.json" -Encoding UTF8

# 创建后端 package.json
Write-Host "📦 创建后端 package.json..." -ForegroundColor Yellow
$backendPackageJson = @"
{
  "name": "milan-outline-backend",
  "version": "1.0.0",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev",
    "db:studio": "prisma studio"
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.0",
    "passport": "^0.7.0",
    "passport-jwt": "^4.0.1",
    "socket.io": "^4.7.0",
    "multer": "^1.4.5",
    "@prisma/client": "^5.7.0",
    "redis": "^4.6.0",
    "joi": "^17.11.0",
    "winston": "^3.11.0",
    "dotenv": "^16.3.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.0",
    "@types/cors": "^2.8.0",
    "@types/bcryptjs": "^2.4.0",
    "@types/jsonwebtoken": "^9.0.0",
    "@types/passport": "^1.0.0",
    "@types/passport-jwt": "^3.0.0",
    "@types/multer": "^1.4.0",
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "tsx": "^4.6.0",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.0",
    "supertest": "^6.3.0",
    "@types/supertest": "^2.0.0",
    "prisma": "^5.7.0"
  }
}
"@

$backendPackageJson | Out-File -FilePath "backend/package.json" -Encoding UTF8

# 创建 Docker Compose 文件
Write-Host "🐳 创建 Docker Compose 配置..." -ForegroundColor Yellow
$dockerCompose = @"
version: '3.8'

services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: milan_outline
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/milan_outline
      REDIS_URL: redis://redis:6379
      JWT_SECRET: your-jwt-secret-key
      NODE_ENV: development
    depends_on:
      - postgres
      - redis
    volumes:
      - ./backend:/app
      - /app/node_modules

  frontend:
    build: ./frontend
    ports:
      - "5173:5173"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - backend

volumes:
  postgres_data:
  redis_data:
"@

$dockerCompose | Out-File -FilePath "docker-compose.yml" -Encoding UTF8

# 创建 Prisma Schema
Write-Host "🗄️ 创建 Prisma Schema..." -ForegroundColor Yellow
$prismaSchema = @"
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  username  String   @unique
  email     String   @unique
  password  String
  avatarUrl String?  @map("avatar_url")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  // Relations
  ownedOutlines Outline[]
  permissions   OutlinePermission[]
  versions      OutlineVersion[]

  @@map("users")
}

model Outline {
  id          String   @id @default(cuid())
  title       String
  description String?
  ownerId     String   @map("owner_id")
  isPublic    Boolean  @default(false) @map("is_public")
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")

  // Relations
  owner       User                @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  nodes       OutlineNode[]
  permissions OutlinePermission[]
  versions    OutlineVersion[]

  @@map("outlines")
}

model OutlineNode {
  id         String   @id @default(cuid())
  outlineId  String   @map("outline_id")
  parentId   String?  @map("parent_id")
  title      String
  content    String?
  nodeType   String   @default("text") @map("node_type")
  sortOrder  Int      @map("sort_order")
  level      Int      @default(0)
  isExpanded Boolean  @default(true) @map("is_expanded")
  createdAt  DateTime @default(now()) @map("created_at")
  updatedAt  DateTime @updatedAt @map("updated_at")

  // Relations
  outline  Outline       @relation(fields: [outlineId], references: [id], onDelete: Cascade)
  parent   OutlineNode?  @relation("NodeHierarchy", fields: [parentId], references: [id], onDelete: Cascade)
  children OutlineNode[] @relation("NodeHierarchy")

  @@map("outline_nodes")
}

model OutlinePermission {
  id              String   @id @default(cuid())
  outlineId       String   @map("outline_id")
  userId          String   @map("user_id")
  permissionLevel String   @map("permission_level")
  grantedBy       String   @map("granted_by")
  createdAt       DateTime @default(now()) @map("created_at")

  // Relations
  outline   Outline @relation(fields: [outlineId], references: [id], onDelete: Cascade)
  user      User    @relation(fields: [userId], references: [id], onDelete: Cascade)
  grantedByUser User @relation(fields: [grantedBy], references: [id])

  @@unique([outlineId, userId])
  @@map("outline_permissions")
}

model OutlineVersion {
  id            String   @id @default(cuid())
  outlineId     String   @map("outline_id")
  versionNumber Int      @map("version_number")
  snapshotData  Json     @map("snapshot_data")
  createdBy     String   @map("created_by")
  createdAt     DateTime @default(now()) @map("created_at")

  // Relations
  outline   Outline @relation(fields: [outlineId], references: [id], onDelete: Cascade)
  createdByUser User @relation(fields: [createdBy], references: [id])

  @@map("outline_versions")
}
"@

$prismaSchema | Out-File -FilePath "backend/prisma/schema.prisma" -Encoding UTF8

# 创建环境变量文件
Write-Host "🔧 创建环境变量文件..." -ForegroundColor Yellow
$envExample = @"
# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/milan_outline"

# Redis
REDIS_URL="redis://localhost:6379"

# JWT
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"
JWT_EXPIRES_IN="7d"

# Server
PORT=3000
NODE_ENV=development

# CORS
CORS_ORIGIN="http://localhost:5173"

# File Upload
MAX_FILE_SIZE=10485760
UPLOAD_PATH="./uploads"
"@

$envExample | Out-File -FilePath "backend/.env.example" -Encoding UTF8
$envExample | Out-File -FilePath "backend/.env" -Encoding UTF8

# 创建 README 文件
Write-Host "📝 创建项目 README..." -ForegroundColor Yellow
$readmeContent = @"
# MilanOutline

一个为 Milannote 设计的强大大纲功能插件，提供层次化的内容组织和实时协作能力。

## 功能特性

- 🌳 **层次化大纲**: 支持无限层级的大纲结构
- 🎯 **拖拽排序**: 直观的拖拽操作重新组织内容
- 👥 **实时协作**: 多人同时编辑，实时同步更新
- 🔒 **权限管理**: 灵活的读写权限控制
- 📱 **响应式设计**: 完美适配桌面和移动设备
- 🔍 **搜索功能**: 快速查找大纲内容
- 📝 **富文本编辑**: 支持格式化文本编辑
- 💾 **版本历史**: 自动保存编辑历史

## 技术栈

### 前端
- React 18 + TypeScript
- Vite (构建工具)
- Ant Design (UI 组件库)
- Zustand (状态管理)
- @dnd-kit (拖拽功能)
- Socket.io (实时通信)

### 后端
- Node.js + Express
- TypeScript
- Prisma (ORM)
- PostgreSQL (数据库)
- Redis (缓存)
- Socket.io (WebSocket)

## 快速开始

### 环境要求
- Node.js 18+
- PostgreSQL 14+
- Redis 7+

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd milan-outline
   ```

2. **安装依赖**
   ```bash
   # 安装前端依赖
   cd frontend
   npm install

   # 安装后端依赖
   cd ../backend
   npm install
   ```

3. **配置环境变量**
   ```bash
   cd backend
   cp .env.example .env
   # 编辑 .env 文件，配置数据库连接等信息
   ```

4. **初始化数据库**
   ```bash
   cd backend
   npm run db:generate
   npm run db:push
   ```

5. **启动开发服务器**
   ```bash
   # 启动后端服务 (终端1)
   cd backend
   npm run dev

   # 启动前端服务 (终端2)
   cd frontend
   npm run dev
   ```

6. **访问应用**
   - 前端: http://localhost:5173
   - 后端 API: http://localhost:3000

### 使用 Docker (推荐)

```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 项目结构

```
milan-outline/
├── frontend/           # React 前端应用
├── backend/           # Node.js 后端 API
├── shared/            # 共享类型和工具
├── docs/              # 项目文档
├── docker-compose.yml # Docker 配置
└── README.md
```

## 开发指南

### 代码规范
- 使用 ESLint + Prettier 进行代码格式化
- 提交前自动运行代码检查
- 遵循 TypeScript 严格模式

### 测试
```bash
# 运行前端测试
cd frontend
npm test

# 运行后端测试
cd backend
npm test
```

### 构建部署
```bash
# 构建前端
cd frontend
npm run build

# 构建后端
cd backend
npm run build
```

## API 文档

启动后端服务后，访问 http://localhost:3000/api-docs 查看完整的 API 文档。

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 支持

如果您遇到任何问题或有功能建议，请创建 [Issue](../../issues)。
"@

$readmeContent | Out-File -FilePath "README.md" -Encoding UTF8

Write-Host "✅ 项目初始化完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📋 下一步操作:" -ForegroundColor Cyan
Write-Host "  1. cd frontend && npm install" -ForegroundColor White
Write-Host "  2. cd backend && npm install" -ForegroundColor White
Write-Host "  3. 配置 backend/.env 文件" -ForegroundColor White
Write-Host "  4. docker-compose up -d (启动数据库)" -ForegroundColor White
Write-Host "  5. cd backend && npm run db:generate && npm run db:push" -ForegroundColor White
Write-Host "  6. 分别启动前后端开发服务器" -ForegroundColor White
Write-Host ""
Write-Host "🎉 开始您的 MilanOutline 开发之旅吧！" -ForegroundColor Green
