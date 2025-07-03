# MilanOutline 系统设计文档

## 项目概述

MilanOutline 是为 Milannote 设计的大纲功能插件，提供层次化的内容组织和管理能力。

## 系统架构

### 整体架构图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端界面      │    │   后端API       │    │   数据存储      │
│                 │    │                 │    │                 │
│ - React组件     │◄──►│ - Express.js    │◄──►│ - PostgreSQL    │
│ - 大纲编辑器    │    │ - RESTful API   │    │ - Redis缓存     │
│ - 拖拽排序      │    │ - WebSocket     │    │ - 文件存储      │
│ - 实时协作      │    │ - 权限控制      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 技术栈选择

### 前端技术栈
- **框架**: React 18 + TypeScript
- **构建工具**: Vite
- **状态管理**: Zustand
- **UI组件库**: Ant Design
- **拖拽功能**: @dnd-kit/core
- **富文本编辑**: Slate.js
- **实时通信**: Socket.io-client

### 后端技术栈
- **运行环境**: Node.js 18+
- **框架**: Express.js
- **语言**: TypeScript
- **数据库ORM**: Prisma
- **身份验证**: JWT + Passport.js
- **实时通信**: Socket.io
- **文件上传**: Multer
- **API文档**: Swagger

### 数据库设计
- **主数据库**: PostgreSQL 14+
- **缓存**: Redis 7+
- **文件存储**: 本地存储 / AWS S3

## 数据库设计

### 核心表结构

#### 1. 用户表 (users)
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  avatar_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. 大纲文档表 (outlines)
```sql
CREATE TABLE outlines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  description TEXT,
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 3. 大纲节点表 (outline_nodes)
```sql
CREATE TABLE outline_nodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outline_id UUID REFERENCES outlines(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES outline_nodes(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  content TEXT,
  node_type VARCHAR(20) DEFAULT 'text', -- text, image, link, file
  sort_order INTEGER NOT NULL,
  level INTEGER NOT NULL DEFAULT 0,
  is_expanded BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4. 协作权限表 (outline_permissions)
```sql
CREATE TABLE outline_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outline_id UUID REFERENCES outlines(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  permission_level VARCHAR(20) NOT NULL, -- read, write, admin
  granted_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(outline_id, user_id)
);
```

#### 5. 版本历史表 (outline_versions)
```sql
CREATE TABLE outline_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outline_id UUID REFERENCES outlines(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  snapshot_data JSONB NOT NULL,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API 设计

### 认证相关 API
```
POST /api/auth/register     # 用户注册
POST /api/auth/login        # 用户登录
POST /api/auth/logout       # 用户登出
GET  /api/auth/profile      # 获取用户信息
PUT  /api/auth/profile      # 更新用户信息
```

### 大纲管理 API
```
GET    /api/outlines              # 获取用户的大纲列表
POST   /api/outlines              # 创建新大纲
GET    /api/outlines/:id          # 获取大纲详情
PUT    /api/outlines/:id          # 更新大纲信息
DELETE /api/outlines/:id          # 删除大纲
```

### 节点操作 API
```
GET    /api/outlines/:id/nodes           # 获取大纲的所有节点
POST   /api/outlines/:id/nodes           # 创建新节点
PUT    /api/outlines/:id/nodes/:nodeId   # 更新节点
DELETE /api/outlines/:id/nodes/:nodeId   # 删除节点
POST   /api/outlines/:id/nodes/reorder   # 重新排序节点
```

### 协作相关 API
```
GET    /api/outlines/:id/permissions     # 获取协作权限
POST   /api/outlines/:id/permissions     # 添加协作者
PUT    /api/outlines/:id/permissions/:userId  # 更新权限
DELETE /api/outlines/:id/permissions/:userId  # 移除协作者
```

## 前端组件设计

### 组件层次结构
```
App
├── Layout
│   ├── Header
│   ├── Sidebar
│   └── MainContent
├── OutlineList
│   └── OutlineCard
├── OutlineEditor
│   ├── OutlineHeader
│   ├── NodeTree
│   │   └── NodeItem
│   └── NodeEditor
└── CollaborationPanel
    ├── UserList
    └── PermissionManager
```

### 核心组件功能

#### 1. OutlineEditor 大纲编辑器
- 树形结构展示
- 拖拽重排序
- 实时编辑
- 多级缩进
- 折叠/展开

#### 2. NodeItem 节点组件
- 支持多种内容类型
- 内联编辑
- 快捷键操作
- 上下文菜单

#### 3. CollaborationPanel 协作面板
- 在线用户显示
- 权限管理
- 实时光标显示

## 实时协作设计

### WebSocket 事件定义
```typescript
// 客户端发送事件
interface ClientEvents {
  'join-outline': (outlineId: string) => void;
  'leave-outline': (outlineId: string) => void;
  'node-update': (nodeId: string, data: Partial<Node>) => void;
  'cursor-position': (position: CursorPosition) => void;
}

// 服务端发送事件
interface ServerEvents {
  'user-joined': (user: User) => void;
  'user-left': (userId: string) => void;
  'node-updated': (nodeId: string, data: Partial<Node>) => void;
  'cursor-moved': (userId: string, position: CursorPosition) => void;
}
```

### 冲突解决策略
- 使用操作变换 (Operational Transformation)
- 最后写入获胜 (Last Write Wins)
- 版本向量时间戳

## 性能优化策略

### 前端优化
1. **虚拟滚动**: 处理大型大纲
2. **懒加载**: 按需加载节点内容
3. **防抖处理**: 减少API调用频率
4. **缓存策略**: 本地存储常用数据

### 后端优化
1. **数据库索引**: 优化查询性能
2. **Redis缓存**: 缓存热点数据
3. **分页查询**: 避免大量数据传输
4. **连接池**: 优化数据库连接

## 安全设计

### 身份验证
- JWT Token 认证
- Token 刷新机制
- 密码加密存储

### 权限控制
- 基于角色的访问控制 (RBAC)
- 资源级权限验证
- API 接口鉴权

### 数据安全
- SQL 注入防护
- XSS 攻击防护
- CSRF 保护
- 输入数据验证

## 部署架构

### 开发环境
```
Docker Compose:
- Frontend (React Dev Server)
- Backend (Node.js)
- PostgreSQL
- Redis
```

### 生产环境
```
Kubernetes 集群:
- Frontend (Nginx + React Build)
- Backend (Node.js Pods)
- PostgreSQL (Managed Service)
- Redis (Managed Service)
- Load Balancer
```

## 监控与日志

### 应用监控
- 性能指标收集
- 错误追踪
- 用户行为分析

### 日志管理
- 结构化日志
- 日志聚合
- 告警机制

## 开发计划

### 第一阶段 (MVP)
- [ ] 基础大纲创建和编辑
- [ ] 节点的增删改查
- [ ] 简单的拖拽排序
- [ ] 用户认证系统

### 第二阶段 (协作功能)
- [ ] 实时协作编辑
- [ ] 权限管理系统
- [ ] 版本历史记录
- [ ] 评论和批注

### 第三阶段 (高级功能)
- [ ] 模板系统
- [ ] 导入导出功能
- [ ] 搜索和过滤
- [ ] 移动端适配

## 技术风险与应对

### 主要风险
1. **实时协作复杂性**: 采用成熟的 OT 算法
2. **性能瓶颈**: 提前进行性能测试
3. **数据一致性**: 使用事务和锁机制
4. **扩展性问题**: 微服务架构预留

### 应对策略
- 分阶段开发，逐步验证
- 充分的单元测试和集成测试
- 性能基准测试
- 代码审查和质量控制

## 详细实现指南

### 项目结构
```
milan-outline/
├── frontend/                 # React 前端
│   ├── src/
│   │   ├── components/      # 可复用组件
│   │   ├── pages/          # 页面组件
│   │   ├── hooks/          # 自定义 Hooks
│   │   ├── store/          # 状态管理
│   │   ├── services/       # API 服务
│   │   ├── types/          # TypeScript 类型
│   │   └── utils/          # 工具函数
│   ├── public/
│   └── package.json
├── backend/                  # Node.js 后端
│   ├── src/
│   │   ├── controllers/    # 控制器
│   │   ├── services/       # 业务逻辑
│   │   ├── models/         # 数据模型
│   │   ├── middleware/     # 中间件
│   │   ├── routes/         # 路由定义
│   │   ├── utils/          # 工具函数
│   │   └── types/          # TypeScript 类型
│   ├── prisma/             # 数据库 Schema
│   └── package.json
├── shared/                   # 共享类型和工具
│   ├── types/
│   └── utils/
├── docs/                     # 文档
├── docker-compose.yml        # 开发环境
└── README.md
```

### 核心数据类型定义

```typescript
// 用户类型
interface User {
  id: string;
  username: string;
  email: string;
  avatarUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

// 大纲类型
interface Outline {
  id: string;
  title: string;
  description?: string;
  ownerId: string;
  isPublic: boolean;
  nodes: OutlineNode[];
  permissions: OutlinePermission[];
  createdAt: Date;
  updatedAt: Date;
}

// 大纲节点类型
interface OutlineNode {
  id: string;
  outlineId: string;
  parentId?: string;
  title: string;
  content?: string;
  nodeType: 'text' | 'image' | 'link' | 'file';
  sortOrder: number;
  level: number;
  isExpanded: boolean;
  children?: OutlineNode[];
  createdAt: Date;
  updatedAt: Date;
}

// 权限类型
interface OutlinePermission {
  id: string;
  outlineId: string;
  userId: string;
  permissionLevel: 'read' | 'write' | 'admin';
  grantedBy: string;
  createdAt: Date;
}
```

### 状态管理设计 (Zustand)

```typescript
// 大纲状态管理
interface OutlineStore {
  // 状态
  currentOutline: Outline | null;
  outlines: Outline[];
  selectedNodeId: string | null;
  isLoading: boolean;
  error: string | null;

  // 操作
  setCurrentOutline: (outline: Outline) => void;
  addNode: (parentId: string | null, node: Partial<OutlineNode>) => void;
  updateNode: (nodeId: string, updates: Partial<OutlineNode>) => void;
  deleteNode: (nodeId: string) => void;
  reorderNodes: (nodeIds: string[]) => void;

  // 异步操作
  fetchOutlines: () => Promise<void>;
  createOutline: (outline: Partial<Outline>) => Promise<void>;
  saveOutline: () => Promise<void>;
}
```

### 实时协作实现

```typescript
// WebSocket 服务
class CollaborationService {
  private socket: Socket;
  private outlineId: string;

  constructor(outlineId: string) {
    this.outlineId = outlineId;
    this.socket = io('/collaboration');
    this.setupEventListeners();
  }

  private setupEventListeners() {
    this.socket.on('node-updated', this.handleNodeUpdate);
    this.socket.on('user-joined', this.handleUserJoined);
    this.socket.on('cursor-moved', this.handleCursorMoved);
  }

  joinOutline() {
    this.socket.emit('join-outline', this.outlineId);
  }

  updateNode(nodeId: string, data: Partial<OutlineNode>) {
    this.socket.emit('node-update', { nodeId, data });
  }

  private handleNodeUpdate = (update: NodeUpdate) => {
    // 处理节点更新
  };
}
```

### 拖拽功能实现

```typescript
// 使用 @dnd-kit 实现拖拽
import { DndContext, DragEndEvent } from '@dnd-kit/core';
import { SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable';

function OutlineTree({ nodes }: { nodes: OutlineNode[] }) {
  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;

    if (active.id !== over?.id) {
      // 重新排序逻辑
      reorderNodes(active.id as string, over?.id as string);
    }
  };

  return (
    <DndContext onDragEnd={handleDragEnd}>
      <SortableContext items={nodes} strategy={verticalListSortingStrategy}>
        {nodes.map(node => (
          <SortableNodeItem key={node.id} node={node} />
        ))}
      </SortableContext>
    </DndContext>
  );
}
```

### 数据库查询优化

```sql
-- 创建必要的索引
CREATE INDEX idx_outline_nodes_outline_id ON outline_nodes(outline_id);
CREATE INDEX idx_outline_nodes_parent_id ON outline_nodes(parent_id);
CREATE INDEX idx_outline_nodes_sort_order ON outline_nodes(outline_id, sort_order);
CREATE INDEX idx_outline_permissions_outline_user ON outline_permissions(outline_id, user_id);

-- 递归查询获取完整的节点树
WITH RECURSIVE node_tree AS (
  -- 根节点
  SELECT id, outline_id, parent_id, title, content, level, sort_order,
         ARRAY[sort_order] as path
  FROM outline_nodes
  WHERE outline_id = $1 AND parent_id IS NULL

  UNION ALL

  -- 子节点
  SELECT n.id, n.outline_id, n.parent_id, n.title, n.content, n.level, n.sort_order,
         nt.path || n.sort_order
  FROM outline_nodes n
  INNER JOIN node_tree nt ON n.parent_id = nt.id
)
SELECT * FROM node_tree ORDER BY path;
```

### API 中间件设计

```typescript
// 认证中间件
export const authenticateToken = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.sendStatus(401);
  }

  jwt.verify(token, process.env.JWT_SECRET!, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// 权限检查中间件
export const checkOutlinePermission = (requiredLevel: PermissionLevel) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    const { outlineId } = req.params;
    const userId = req.user.id;

    const permission = await prisma.outlinePermission.findFirst({
      where: { outlineId, userId }
    });

    if (!permission || !hasPermission(permission.permissionLevel, requiredLevel)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
};
```

### 错误处理策略

```typescript
// 全局错误处理中间件
export const errorHandler = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  logger.error('Unhandled error:', error);

  if (error instanceof ValidationError) {
    return res.status(400).json({
      error: 'Validation failed',
      details: error.details
    });
  }

  if (error instanceof NotFoundError) {
    return res.status(404).json({
      error: 'Resource not found'
    });
  }

  res.status(500).json({
    error: 'Internal server error'
  });
};

// 前端错误边界
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
    // 发送错误报告到监控服务
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback />;
    }

    return this.props.children;
  }
}
```

### 测试策略

```typescript
// 单元测试示例 (Jest + React Testing Library)
describe('OutlineNode', () => {
  it('should render node title correctly', () => {
    const node = createMockNode({ title: 'Test Node' });
    render(<OutlineNode node={node} />);

    expect(screen.getByText('Test Node')).toBeInTheDocument();
  });

  it('should handle node update', async () => {
    const onUpdate = jest.fn();
    const node = createMockNode();

    render(<OutlineNode node={node} onUpdate={onUpdate} />);

    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: 'Updated Title' } });
    fireEvent.blur(input);

    await waitFor(() => {
      expect(onUpdate).toHaveBeenCalledWith(node.id, { title: 'Updated Title' });
    });
  });
});

// 集成测试示例
describe('Outline API', () => {
  it('should create and retrieve outline', async () => {
    const user = await createTestUser();
    const token = generateTestToken(user);

    const outlineData = {
      title: 'Test Outline',
      description: 'Test Description'
    };

    const createResponse = await request(app)
      .post('/api/outlines')
      .set('Authorization', `Bearer ${token}`)
      .send(outlineData)
      .expect(201);

    const outlineId = createResponse.body.id;

    const getResponse = await request(app)
      .get(`/api/outlines/${outlineId}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(getResponse.body.title).toBe(outlineData.title);
  });
});
```

## 部署配置

### Docker 配置

```dockerfile
# Frontend Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# Backend Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

### Kubernetes 部署配置

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: milan-outline-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: milan-outline-backend
  template:
    metadata:
      labels:
        app: milan-outline-backend
    spec:
      containers:
      - name: backend
        image: milan-outline-backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: milan-outline-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: milan-outline-secrets
              key: jwt-secret
```

### 监控配置

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'milan-outline-backend'
    static_configs:
      - targets: ['backend:3000']
    metrics_path: '/metrics'

  - job_name: 'milan-outline-frontend'
    static_configs:
      - targets: ['frontend:80']
```

## 开发工作流

### Git 工作流
1. **主分支**: `main` - 生产环境代码
2. **开发分支**: `develop` - 开发环境代码
3. **功能分支**: `feature/xxx` - 新功能开发
4. **修复分支**: `hotfix/xxx` - 紧急修复

### 代码质量控制
- ESLint + Prettier 代码格式化
- Husky + lint-staged 提交前检查
- 单元测试覆盖率 > 80%
- 代码审查必须通过

### CI/CD 流程
1. 代码提交触发构建
2. 运行单元测试和集成测试
3. 代码质量检查
4. 构建 Docker 镜像
5. 部署到测试环境
6. 自动化测试验证
7. 部署到生产环境

这个系统设计文档涵盖了 MilanOutline 项目的完整架构，包括技术选型、数据库设计、API 设计、前端组件、实时协作、性能优化、安全设计、部署方案等各个方面。您可以基于这个设计文档开始项目的具体实现。
