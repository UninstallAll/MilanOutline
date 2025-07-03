# MilanOutline 浏览器插件快速创建脚本

Write-Host "🚀 创建 MilanOutline 浏览器插件项目..." -ForegroundColor Green

# 创建项目目录结构
Write-Host "📁 创建项目目录结构..." -ForegroundColor Yellow

$directories = @(
    "src/popup",
    "src/content", 
    "src/background",
    "src/components/OutlineEditor",
    "src/components/NodeItem",
    "src/components/Sidebar",
    "src/hooks",
    "src/utils",
    "src/types",
    "src/styles",
    "public/icons",
    "public/images"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  ✓ 创建目录: $dir" -ForegroundColor Gray
}

# 创建 package.json
Write-Host "📦 创建 package.json..." -ForegroundColor Yellow
$packageJson = @"
{
  "name": "milan-outline-extension",
  "version": "1.0.0",
  "description": "轻量级大纲管理浏览器插件",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "antd": "^5.12.0",
    "@ant-design/icons": "^5.2.0",
    "@dnd-kit/core": "^6.1.0",
    "@dnd-kit/sortable": "^8.0.0",
    "@dnd-kit/utilities": "^3.2.0",
    "zustand": "^4.4.0",
    "nanoid": "^5.0.0",
    "dayjs": "^1.11.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@types/chrome": "^0.0.246",
    "@vitejs/plugin-react": "^4.0.0",
    "@crxjs/vite-plugin": "^2.0.0-beta.19",
    "typescript": "^5.0.2",
    "vite": "^4.4.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "tailwindcss": "^3.3.0"
  }
}
"@

$packageJson | Out-File -FilePath "package.json" -Encoding UTF8

# 创建 manifest.json
Write-Host "🔧 创建 manifest.json..." -ForegroundColor Yellow
$manifest = @"
{
  "manifest_version": 3,
  "name": "MilanOutline",
  "version": "1.0.0",
  "description": "轻量级大纲管理工具，支持层次化内容组织和拖拽排序",
  "permissions": [
    "storage",
    "activeTab"
  ],
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["src/content/index.ts"],
      "css": ["src/content/content.css"]
    }
  ],
  "background": {
    "service_worker": "src/background/index.ts"
  },
  "action": {
    "default_popup": "src/popup/popup.html",
    "default_title": "MilanOutline - 大纲管理",
    "default_icon": {
      "16": "public/icons/icon-16.png",
      "32": "public/icons/icon-32.png",
      "48": "public/icons/icon-48.png",
      "128": "public/icons/icon-128.png"
    }
  },
  "icons": {
    "16": "public/icons/icon-16.png",
    "32": "public/icons/icon-32.png",
    "48": "public/icons/icon-48.png",
    "128": "public/icons/icon-128.png"
  },
  "commands": {
    "toggle-outline": {
      "suggested_key": {
        "default": "Ctrl+Shift+O",
        "mac": "Command+Shift+O"
      },
      "description": "切换大纲侧边栏显示/隐藏"
    },
    "add-node": {
      "suggested_key": {
        "default": "Ctrl+Shift+N",
        "mac": "Command+Shift+N"
      },
      "description": "添加新的大纲节点"
    },
    "focus-search": {
      "suggested_key": {
        "default": "Ctrl+Shift+F",
        "mac": "Command+Shift+F"
      },
      "description": "聚焦到搜索框"
    }
  },
  "web_accessible_resources": [
    {
      "resources": ["src/content/*", "public/*"],
      "matches": ["<all_urls>"]
    }
  ]
}
"@

$manifest | Out-File -FilePath "public/manifest.json" -Encoding UTF8

# 创建 Vite 配置
Write-Host "⚡ 创建 vite.config.ts..." -ForegroundColor Yellow
$viteConfig = @"
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { crx } from '@crxjs/vite-plugin';
import manifest from './public/manifest.json';

export default defineConfig({
  plugins: [
    react(),
    crx({ manifest })
  ],
  build: {
    rollupOptions: {
      input: {
        popup: 'src/popup/popup.html'
      }
    }
  }
});
"@

$viteConfig | Out-File -FilePath "vite.config.ts" -Encoding UTF8

# 创建 TypeScript 配置
Write-Host "📝 创建 tsconfig.json..." -ForegroundColor Yellow
$tsConfig = @"
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "types": ["chrome", "vite/client"]
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
"@

$tsConfig | Out-File -FilePath "tsconfig.json" -Encoding UTF8

# 创建类型定义文件
Write-Host "🏷️ 创建类型定义..." -ForegroundColor Yellow
$types = @"
// src/types/index.ts
export interface OutlineNode {
  id: string;
  title: string;
  content?: string;
  parentId?: string;
  children: OutlineNode[];
  level: number;
  sortOrder: number;
  isExpanded: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface Outline {
  id: string;
  title: string;
  description?: string;
  nodes: OutlineNode[];
  createdAt: Date;
  updatedAt: Date;
}

export interface AppState {
  outlines: Outline[];
  currentOutlineId: string | null;
  selectedNodeId: string | null;
  isLoading: boolean;
  searchQuery: string;
}

export interface StorageData {
  outlines: Outline[];
  settings: AppSettings;
}

export interface AppSettings {
  theme: 'light' | 'dark';
  sidebarWidth: number;
  autoSave: boolean;
  shortcuts: Record<string, string>;
}

export type MessageType = 
  | 'TOGGLE_SIDEBAR'
  | 'ADD_NODE'
  | 'UPDATE_NODE'
  | 'DELETE_NODE'
  | 'FOCUS_SEARCH';

export interface Message {
  type: MessageType;
  payload?: any;
}
"@

$types | Out-File -FilePath "src/types/index.ts" -Encoding UTF8

# 创建存储管理器
Write-Host "💾 创建存储管理器..." -ForegroundColor Yellow
$storage = @"
// src/utils/storage.ts
import { StorageData, Outline, AppSettings } from '../types';

export class StorageManager {
  private static instance: StorageManager;
  
  static getInstance(): StorageManager {
    if (!StorageManager.instance) {
      StorageManager.instance = new StorageManager();
    }
    return StorageManager.instance;
  }
  
  async saveOutlines(outlines: Outline[]): Promise<void> {
    await chrome.storage.local.set({ outlines });
  }
  
  async loadOutlines(): Promise<Outline[]> {
    const result = await chrome.storage.local.get(['outlines']);
    return result.outlines || [];
  }
  
  async saveSettings(settings: AppSettings): Promise<void> {
    await chrome.storage.local.set({ settings });
  }
  
  async loadSettings(): Promise<AppSettings> {
    const result = await chrome.storage.local.get(['settings']);
    return result.settings || this.getDefaultSettings();
  }
  
  async exportData(): Promise<string> {
    const data = await chrome.storage.local.get();
    return JSON.stringify(data, null, 2);
  }
  
  async importData(jsonData: string): Promise<void> {
    try {
      const data = JSON.parse(jsonData);
      await chrome.storage.local.set(data);
    } catch (error) {
      throw new Error('Invalid JSON data');
    }
  }
  
  async clearAll(): Promise<void> {
    await chrome.storage.local.clear();
  }
  
  private getDefaultSettings(): AppSettings {
    return {
      theme: 'light',
      sidebarWidth: 400,
      autoSave: true,
      shortcuts: {
        'toggle-outline': 'Ctrl+Shift+O',
        'add-node': 'Ctrl+Shift+N',
        'focus-search': 'Ctrl+Shift+F'
      }
    };
  }
}
"@

$storage | Out-File -FilePath "src/utils/storage.ts" -Encoding UTF8

# 创建状态管理
Write-Host "🏪 创建状态管理..." -ForegroundColor Yellow
$store = @"
// src/hooks/useStore.ts
import { create } from 'zustand';
import { nanoid } from 'nanoid';
import { Outline, OutlineNode, AppState } from '../types';
import { StorageManager } from '../utils/storage';

interface StoreActions {
  // 大纲操作
  createOutline: (title: string, description?: string) => Promise<void>;
  updateOutline: (id: string, updates: Partial<Outline>) => Promise<void>;
  deleteOutline: (id: string) => Promise<void>;
  setCurrentOutline: (id: string | null) => void;
  
  // 节点操作
  addNode: (parentId?: string, title?: string) => Promise<void>;
  updateNode: (id: string, updates: Partial<OutlineNode>) => Promise<void>;
  deleteNode: (id: string) => Promise<void>;
  moveNode: (nodeId: string, newParentId?: string, newIndex?: number) => Promise<void>;
  toggleNodeExpansion: (id: string) => Promise<void>;
  
  // UI 状态
  setSelectedNode: (id: string | null) => void;
  setSearchQuery: (query: string) => void;
  setLoading: (loading: boolean) => void;
  
  // 数据持久化
  loadData: () => Promise<void>;
  saveData: () => Promise<void>;
}

type Store = AppState & StoreActions;

export const useStore = create<Store>((set, get) => ({
  // 初始状态
  outlines: [],
  currentOutlineId: null,
  selectedNodeId: null,
  isLoading: false,
  searchQuery: '',
  
  // 大纲操作
  createOutline: async (title: string, description?: string) => {
    const newOutline: Outline = {
      id: nanoid(),
      title,
      description,
      nodes: [],
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    set(state => ({
      outlines: [...state.outlines, newOutline],
      currentOutlineId: newOutline.id
    }));
    
    await get().saveData();
  },
  
  updateOutline: async (id: string, updates: Partial<Outline>) => {
    set(state => ({
      outlines: state.outlines.map(outline =>
        outline.id === id
          ? { ...outline, ...updates, updatedAt: new Date() }
          : outline
      )
    }));
    
    await get().saveData();
  },
  
  deleteOutline: async (id: string) => {
    set(state => ({
      outlines: state.outlines.filter(outline => outline.id !== id),
      currentOutlineId: state.currentOutlineId === id ? null : state.currentOutlineId
    }));
    
    await get().saveData();
  },
  
  setCurrentOutline: (id: string | null) => {
    set({ currentOutlineId: id, selectedNodeId: null });
  },
  
  // 节点操作
  addNode: async (parentId?: string, title = '新节点') => {
    const { currentOutlineId, outlines } = get();
    if (!currentOutlineId) return;
    
    const currentOutline = outlines.find(o => o.id === currentOutlineId);
    if (!currentOutline) return;
    
    const newNode: OutlineNode = {
      id: nanoid(),
      title,
      content: '',
      parentId,
      children: [],
      level: parentId ? (findNodeById(currentOutline.nodes, parentId)?.level || 0) + 1 : 0,
      sortOrder: getNextSortOrder(currentOutline.nodes, parentId),
      isExpanded: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const updatedNodes = addNodeToTree(currentOutline.nodes, newNode, parentId);
    
    set(state => ({
      outlines: state.outlines.map(outline =>
        outline.id === currentOutlineId
          ? { ...outline, nodes: updatedNodes, updatedAt: new Date() }
          : outline
      ),
      selectedNodeId: newNode.id
    }));
    
    await get().saveData();
  },
  
  updateNode: async (id: string, updates: Partial<OutlineNode>) => {
    const { currentOutlineId, outlines } = get();
    if (!currentOutlineId) return;
    
    set(state => ({
      outlines: state.outlines.map(outline =>
        outline.id === currentOutlineId
          ? {
              ...outline,
              nodes: updateNodeInTree(outline.nodes, id, { ...updates, updatedAt: new Date() }),
              updatedAt: new Date()
            }
          : outline
      )
    }));
    
    await get().saveData();
  },
  
  deleteNode: async (id: string) => {
    const { currentOutlineId, outlines, selectedNodeId } = get();
    if (!currentOutlineId) return;
    
    set(state => ({
      outlines: state.outlines.map(outline =>
        outline.id === currentOutlineId
          ? {
              ...outline,
              nodes: removeNodeFromTree(outline.nodes, id),
              updatedAt: new Date()
            }
          : outline
      ),
      selectedNodeId: selectedNodeId === id ? null : selectedNodeId
    }));
    
    await get().saveData();
  },
  
  moveNode: async (nodeId: string, newParentId?: string, newIndex?: number) => {
    // TODO: 实现节点移动逻辑
    await get().saveData();
  },
  
  toggleNodeExpansion: async (id: string) => {
    await get().updateNode(id, { isExpanded: !findNodeById(get().outlines.find(o => o.id === get().currentOutlineId)?.nodes || [], id)?.isExpanded });
  },
  
  // UI 状态
  setSelectedNode: (id: string | null) => set({ selectedNodeId: id }),
  setSearchQuery: (query: string) => set({ searchQuery: query }),
  setLoading: (loading: boolean) => set({ isLoading: loading }),
  
  // 数据持久化
  loadData: async () => {
    set({ isLoading: true });
    try {
      const storage = StorageManager.getInstance();
      const outlines = await storage.loadOutlines();
      set({ outlines });
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      set({ isLoading: false });
    }
  },
  
  saveData: async () => {
    try {
      const storage = StorageManager.getInstance();
      await storage.saveOutlines(get().outlines);
    } catch (error) {
      console.error('Failed to save data:', error);
    }
  }
}));

// 辅助函数
function findNodeById(nodes: OutlineNode[], id: string): OutlineNode | null {
  for (const node of nodes) {
    if (node.id === id) return node;
    const found = findNodeById(node.children, id);
    if (found) return found;
  }
  return null;
}

function getNextSortOrder(nodes: OutlineNode[], parentId?: string): number {
  const siblings = parentId 
    ? findNodeById(nodes, parentId)?.children || []
    : nodes.filter(n => !n.parentId);
  
  return siblings.length > 0 
    ? Math.max(...siblings.map(n => n.sortOrder)) + 1 
    : 0;
}

function addNodeToTree(nodes: OutlineNode[], newNode: OutlineNode, parentId?: string): OutlineNode[] {
  if (!parentId) {
    return [...nodes, newNode];
  }
  
  return nodes.map(node => {
    if (node.id === parentId) {
      return {
        ...node,
        children: [...node.children, newNode]
      };
    }
    return {
      ...node,
      children: addNodeToTree(node.children, newNode, parentId)
    };
  });
}

function updateNodeInTree(nodes: OutlineNode[], id: string, updates: Partial<OutlineNode>): OutlineNode[] {
  return nodes.map(node => {
    if (node.id === id) {
      return { ...node, ...updates };
    }
    return {
      ...node,
      children: updateNodeInTree(node.children, id, updates)
    };
  });
}

function removeNodeFromTree(nodes: OutlineNode[], id: string): OutlineNode[] {
  return nodes
    .filter(node => node.id !== id)
    .map(node => ({
      ...node,
      children: removeNodeFromTree(node.children, id)
    }));
}
"@

$store | Out-File -FilePath "src/hooks/useStore.ts" -Encoding UTF8

Write-Host "✅ MilanOutline 浏览器插件项目创建完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📋 下一步操作:" -ForegroundColor Cyan
Write-Host "  1. npm install                    # 安装依赖" -ForegroundColor White
Write-Host "  2. npm run dev                    # 开发模式" -ForegroundColor White
Write-Host "  3. npm run build                  # 构建插件" -ForegroundColor White
Write-Host "  4. 在 Chrome 中加载 dist 文件夹   # 安装插件" -ForegroundColor White
Write-Host ""
Write-Host "🎯 快捷键:" -ForegroundColor Cyan
Write-Host "  Ctrl+Shift+O  切换大纲侧边栏" -ForegroundColor White
Write-Host "  Ctrl+Shift+N  添加新节点" -ForegroundColor White
Write-Host "  Ctrl+Shift+F  聚焦搜索" -ForegroundColor White
Write-Host ""
Write-Host "🎉 开始您的轻量级大纲管理之旅！" -ForegroundColor Green
