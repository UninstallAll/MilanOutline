# MilanOutline 开发规范指南

## 代码规范

### TypeScript 规范

#### 1. 类型定义
```typescript
// ✅ 推荐：使用 interface 定义对象类型
interface User {
  id: string;
  username: string;
  email: string;
  createdAt: Date;
}

// ✅ 推荐：使用 type 定义联合类型
type PermissionLevel = 'read' | 'write' | 'admin';

// ❌ 避免：使用 any 类型
const data: any = fetchData(); // 不推荐

// ✅ 推荐：使用具体类型或泛型
const data: User[] = fetchData<User[]>();
```

#### 2. 函数定义
```typescript
// ✅ 推荐：明确的参数和返回值类型
async function createOutline(
  title: string,
  description?: string
): Promise<Outline> {
  // 实现
}

// ✅ 推荐：使用箭头函数和类型推断
const updateNode = (nodeId: string, updates: Partial<OutlineNode>) => {
  // 实现
};
```

### React 组件规范

#### 1. 组件定义
```typescript
// ✅ 推荐：使用函数组件 + TypeScript
interface OutlineNodeProps {
  node: OutlineNode;
  onUpdate: (nodeId: string, updates: Partial<OutlineNode>) => void;
  onDelete: (nodeId: string) => void;
}

const OutlineNode: React.FC<OutlineNodeProps> = ({
  node,
  onUpdate,
  onDelete
}) => {
  // 组件实现
};

export default OutlineNode;
```

#### 2. Hooks 使用
```typescript
// ✅ 推荐：自定义 Hook
const useOutlineNode = (nodeId: string) => {
  const [node, setNode] = useState<OutlineNode | null>(null);
  const [loading, setLoading] = useState(false);
  
  const updateNode = useCallback((updates: Partial<OutlineNode>) => {
    // 更新逻辑
  }, [nodeId]);
  
  return { node, loading, updateNode };
};
```

### 命名规范

#### 1. 文件命名
```
components/
├── OutlineEditor/
│   ├── index.ts          # 导出文件
│   ├── OutlineEditor.tsx # 主组件
│   ├── OutlineEditor.module.css
│   └── OutlineEditor.test.tsx
├── NodeItem/
│   ├── index.ts
│   ├── NodeItem.tsx
│   └── NodeItem.test.tsx
```

#### 2. 变量命名
```typescript
// ✅ 推荐：使用 camelCase
const userName = 'john_doe';
const isLoading = false;
const nodeList = [];

// ✅ 推荐：常量使用 UPPER_SNAKE_CASE
const API_BASE_URL = 'https://api.example.com';
const MAX_FILE_SIZE = 10 * 1024 * 1024;

// ✅ 推荐：组件使用 PascalCase
const OutlineEditor = () => {};
const NodeItem = () => {};
```

## Git 工作流规范

### 分支命名规范
```
main                    # 主分支，生产环境代码
develop                 # 开发分支，集成最新功能
feature/outline-editor  # 功能分支
feature/real-time-sync  # 功能分支
hotfix/critical-bug     # 紧急修复分支
release/v1.0.0         # 发布分支
```

### 提交信息规范
```
<type>(<scope>): <subject>

<body>

<footer>
```

#### 类型 (type)
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

#### 示例
```
feat(outline): add drag and drop functionality

- Implement node reordering with @dnd-kit
- Add visual feedback during drag operations
- Update node sort order in database

Closes #123
```

### Pull Request 规范

#### PR 标题格式
```
[类型] 简短描述

例如：
[Feature] 添加大纲拖拽排序功能
[Fix] 修复节点删除时的内存泄漏
[Docs] 更新 API 文档
```

#### PR 描述模板
```markdown
## 变更类型
- [ ] 新功能
- [ ] Bug 修复
- [ ] 文档更新
- [ ] 代码重构
- [ ] 性能优化

## 变更描述
简要描述本次变更的内容和目的。

## 测试
- [ ] 单元测试已通过
- [ ] 集成测试已通过
- [ ] 手动测试已完成

## 截图/录屏
如果有 UI 变更，请提供截图或录屏。

## 相关 Issue
Closes #123
```

## 测试规范

### 单元测试
```typescript
// OutlineNode.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { OutlineNode } from './OutlineNode';

describe('OutlineNode', () => {
  const mockNode = {
    id: '1',
    title: 'Test Node',
    content: 'Test content',
    level: 0,
    sortOrder: 1
  };

  it('should render node title', () => {
    render(<OutlineNode node={mockNode} onUpdate={jest.fn()} />);
    expect(screen.getByText('Test Node')).toBeInTheDocument();
  });

  it('should call onUpdate when title changes', () => {
    const onUpdate = jest.fn();
    render(<OutlineNode node={mockNode} onUpdate={onUpdate} />);
    
    const input = screen.getByDisplayValue('Test Node');
    fireEvent.change(input, { target: { value: 'Updated Title' } });
    fireEvent.blur(input);
    
    expect(onUpdate).toHaveBeenCalledWith('1', { title: 'Updated Title' });
  });
});
```

### API 测试
```typescript
// outline.test.ts
import request from 'supertest';
import { app } from '../app';

describe('Outline API', () => {
  describe('POST /api/outlines', () => {
    it('should create a new outline', async () => {
      const outlineData = {
        title: 'Test Outline',
        description: 'Test Description'
      };

      const response = await request(app)
        .post('/api/outlines')
        .set('Authorization', `Bearer ${validToken}`)
        .send(outlineData)
        .expect(201);

      expect(response.body).toMatchObject({
        title: outlineData.title,
        description: outlineData.description
      });
    });
  });
});
```

## 性能优化规范

### React 性能优化
```typescript
// ✅ 推荐：使用 React.memo 优化组件渲染
const NodeItem = React.memo<NodeItemProps>(({ node, onUpdate }) => {
  // 组件实现
});

// ✅ 推荐：使用 useCallback 优化函数引用
const handleNodeUpdate = useCallback((nodeId: string, updates: Partial<OutlineNode>) => {
  // 更新逻辑
}, []);

// ✅ 推荐：使用 useMemo 优化计算结果
const sortedNodes = useMemo(() => {
  return nodes.sort((a, b) => a.sortOrder - b.sortOrder);
}, [nodes]);
```

### 数据库查询优化
```typescript
// ✅ 推荐：使用索引优化查询
await prisma.outlineNode.findMany({
  where: {
    outlineId: id,
    parentId: null // 利用索引
  },
  orderBy: {
    sortOrder: 'asc' // 利用索引
  }
});

// ✅ 推荐：使用 select 减少数据传输
await prisma.outline.findMany({
  select: {
    id: true,
    title: true,
    updatedAt: true
  }
});
```

## 安全规范

### 输入验证
```typescript
// ✅ 推荐：使用 Joi 进行输入验证
const createOutlineSchema = Joi.object({
  title: Joi.string().min(1).max(200).required(),
  description: Joi.string().max(1000).optional(),
  isPublic: Joi.boolean().default(false)
});

// 在控制器中使用
const { error, value } = createOutlineSchema.validate(req.body);
if (error) {
  return res.status(400).json({ error: error.details[0].message });
}
```

### 权限检查
```typescript
// ✅ 推荐：统一的权限检查中间件
const checkPermission = (requiredLevel: PermissionLevel) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    const { outlineId } = req.params;
    const userId = req.user.id;
    
    const hasPermission = await checkUserPermission(userId, outlineId, requiredLevel);
    if (!hasPermission) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    
    next();
  };
};
```

## 错误处理规范

### 前端错误处理
```typescript
// ✅ 推荐：统一的错误处理
class ApiError extends Error {
  constructor(
    public status: number,
    public message: string,
    public code?: string
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

// 在 API 服务中使用
const apiClient = {
  async request<T>(url: string, options?: RequestInit): Promise<T> {
    try {
      const response = await fetch(url, options);
      
      if (!response.ok) {
        throw new ApiError(response.status, response.statusText);
      }
      
      return await response.json();
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Network error');
    }
  }
};
```

### 后端错误处理
```typescript
// ✅ 推荐：自定义错误类
class ValidationError extends Error {
  constructor(public details: any[]) {
    super('Validation failed');
    this.name = 'ValidationError';
  }
}

class NotFoundError extends Error {
  constructor(resource: string) {
    super(`${resource} not found`);
    this.name = 'NotFoundError';
  }
}

// 全局错误处理中间件
const errorHandler = (error: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error('Error:', error);
  
  if (error instanceof ValidationError) {
    return res.status(400).json({
      error: 'Validation failed',
      details: error.details
    });
  }
  
  if (error instanceof NotFoundError) {
    return res.status(404).json({
      error: error.message
    });
  }
  
  res.status(500).json({
    error: 'Internal server error'
  });
};
```

## 文档规范

### 代码注释
```typescript
/**
 * 创建新的大纲节点
 * @param outlineId - 大纲 ID
 * @param parentId - 父节点 ID，根节点为 null
 * @param nodeData - 节点数据
 * @returns 创建的节点信息
 */
async function createNode(
  outlineId: string,
  parentId: string | null,
  nodeData: CreateNodeData
): Promise<OutlineNode> {
  // 实现
}
```

### API 文档
```typescript
/**
 * @swagger
 * /api/outlines:
 *   post:
 *     summary: 创建新大纲
 *     tags: [Outlines]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *                 description: 大纲标题
 *               description:
 *                 type: string
 *                 description: 大纲描述
 *     responses:
 *       201:
 *         description: 大纲创建成功
 *       400:
 *         description: 请求参数错误
 *       401:
 *         description: 未授权
 */
```

## 部署规范

### 环境配置
```bash
# 开发环境
NODE_ENV=development
LOG_LEVEL=debug

# 测试环境
NODE_ENV=test
LOG_LEVEL=info

# 生产环境
NODE_ENV=production
LOG_LEVEL=warn
```

### Docker 最佳实践
```dockerfile
# 使用多阶段构建
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
RUN npm run build

# 使用非 root 用户
USER node
EXPOSE 3000
CMD ["npm", "start"]
```

## 监控和日志规范

### 日志格式
```typescript
// ✅ 推荐：结构化日志
logger.info('User created outline', {
  userId: user.id,
  outlineId: outline.id,
  timestamp: new Date().toISOString(),
  action: 'create_outline'
});

// ✅ 推荐：错误日志包含上下文
logger.error('Failed to create outline', {
  error: error.message,
  stack: error.stack,
  userId: user.id,
  requestId: req.id
});
```

### 性能监控
```typescript
// ✅ 推荐：关键操作添加性能监控
const startTime = Date.now();
const result = await expensiveOperation();
const duration = Date.now() - startTime;

logger.info('Operation completed', {
  operation: 'expensiveOperation',
  duration,
  success: true
});
```

遵循这些开发规范，可以确保代码质量、提高开发效率，并便于团队协作和项目维护。
