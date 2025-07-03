# MilanOutline 轻量级实现方案

## 方案对比

| 方案 | 复杂度 | 启动速度 | 数据持久化 | 协作功能 | 适用场景 |
|------|--------|----------|------------|----------|----------|
| **浏览器插件** | 低 | 极快 | 本地存储 | 无 | 个人使用 |
| **纯前端 PWA** | 低 | 快 | 本地/云端 | 有限 | 轻量协作 |
| **Electron 桌面应用** | 中 | 中等 | 本地文件 | 无 | 离线使用 |
| **静态网站 + 云存储** | 中 | 快 | 云端 | 有限 | 简单协作 |

## 方案一：浏览器插件 (推荐)

### 技术栈
- **框架**: React + TypeScript
- **构建工具**: Vite + CRXJS
- **存储**: Chrome Storage API
- **UI**: Ant Design (轻量版)
- **拖拽**: @dnd-kit

### 项目结构
```
milan-outline-extension/
├── src/
│   ├── content/           # 内容脚本
│   ├── popup/            # 弹窗页面
│   ├── options/          # 设置页面
│   ├── background/       # 后台脚本
│   ├── components/       # 共享组件
│   ├── hooks/           # 自定义 Hooks
│   ├── utils/           # 工具函数
│   └── types/           # 类型定义
├── public/
│   ├── manifest.json    # 插件配置
│   └── icons/          # 图标资源
└── package.json
```

### 核心功能实现

#### 1. 数据存储 (Chrome Storage)
```typescript
// storage.ts
interface OutlineData {
  outlines: Outline[];
  currentOutlineId: string | null;
}

class StorageManager {
  async saveOutlines(outlines: Outline[]): Promise<void> {
    await chrome.storage.local.set({ outlines });
  }
  
  async loadOutlines(): Promise<Outline[]> {
    const result = await chrome.storage.local.get(['outlines']);
    return result.outlines || [];
  }
  
  async exportData(): Promise<string> {
    const data = await chrome.storage.local.get();
    return JSON.stringify(data, null, 2);
  }
  
  async importData(jsonData: string): Promise<void> {
    const data = JSON.parse(jsonData);
    await chrome.storage.local.set(data);
  }
}
```

#### 2. 侧边栏集成
```typescript
// content-script.ts
class OutlineSidebar {
  private sidebar: HTMLElement;
  private isVisible = false;
  
  constructor() {
    this.createSidebar();
    this.setupToggleListener();
  }
  
  private createSidebar() {
    this.sidebar = document.createElement('div');
    this.sidebar.id = 'milan-outline-sidebar';
    this.sidebar.innerHTML = `
      <div class="outline-container">
        <div id="outline-root"></div>
      </div>
    `;
    
    // 添加样式
    this.sidebar.style.cssText = `
      position: fixed;
      top: 0;
      right: -400px;
      width: 400px;
      height: 100vh;
      background: white;
      box-shadow: -2px 0 10px rgba(0,0,0,0.1);
      z-index: 10000;
      transition: right 0.3s ease;
    `;
    
    document.body.appendChild(this.sidebar);
  }
  
  toggle() {
    this.isVisible = !this.isVisible;
    this.sidebar.style.right = this.isVisible ? '0px' : '-400px';
  }
}

// 初始化
new OutlineSidebar();
```

#### 3. 快捷键支持
```typescript
// background.ts
chrome.commands.onCommand.addListener((command) => {
  switch (command) {
    case 'toggle-outline':
      chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
        chrome.tabs.sendMessage(tabs[0].id!, { action: 'toggle-sidebar' });
      });
      break;
    case 'add-node':
      chrome.tabs.sendMessage(tabs[0].id!, { action: 'add-node' });
      break;
  }
});
```

### 安装配置

#### manifest.json
```json
{
  "manifest_version": 3,
  "name": "MilanOutline",
  "version": "1.0.0",
  "description": "轻量级大纲管理工具",
  "permissions": [
    "storage",
    "activeTab"
  ],
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "css": ["content.css"]
    }
  ],
  "background": {
    "service_worker": "background.js"
  },
  "action": {
    "default_popup": "popup.html",
    "default_title": "MilanOutline"
  },
  "commands": {
    "toggle-outline": {
      "suggested_key": {
        "default": "Ctrl+Shift+O"
      },
      "description": "切换大纲显示"
    }
  }
}
```

## 方案二：纯前端 PWA

### 技术栈
- **框架**: React + TypeScript + Vite
- **状态管理**: Zustand + IndexedDB
- **UI**: Ant Design
- **PWA**: Workbox
- **同步**: 可选集成 Google Drive API

### 核心特性
```typescript
// pwa-storage.ts
class PWAStorage {
  private db: IDBDatabase;
  
  async init() {
    return new Promise<void>((resolve, reject) => {
      const request = indexedDB.open('MilanOutline', 1);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };
      
      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        
        // 创建对象存储
        const outlineStore = db.createObjectStore('outlines', { keyPath: 'id' });
        const nodeStore = db.createObjectStore('nodes', { keyPath: 'id' });
        
        // 创建索引
        nodeStore.createIndex('outlineId', 'outlineId', { unique: false });
      };
    });
  }
  
  async saveOutline(outline: Outline): Promise<void> {
    const transaction = this.db.transaction(['outlines'], 'readwrite');
    const store = transaction.objectStore('outlines');
    await store.put(outline);
  }
  
  async loadOutlines(): Promise<Outline[]> {
    const transaction = this.db.transaction(['outlines'], 'readonly');
    const store = transaction.objectStore('outlines');
    const request = store.getAll();
    
    return new Promise((resolve, reject) => {
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }
}
```

### 云同步功能 (可选)
```typescript
// cloud-sync.ts
class CloudSync {
  private driveApi: any;
  
  async syncToCloud(data: any): Promise<void> {
    try {
      await gapi.client.drive.files.create({
        resource: {
          name: 'milan-outline-backup.json',
          parents: ['appDataFolder']
        },
        media: {
          mimeType: 'application/json',
          body: JSON.stringify(data)
        }
      });
    } catch (error) {
      console.error('Cloud sync failed:', error);
    }
  }
  
  async syncFromCloud(): Promise<any> {
    try {
      const response = await gapi.client.drive.files.list({
        q: "name='milan-outline-backup.json' and parents in 'appDataFolder'",
        spaces: 'appDataFolder'
      });
      
      if (response.result.files?.length > 0) {
        const fileId = response.result.files[0].id;
        const file = await gapi.client.drive.files.get({
          fileId,
          alt: 'media'
        });
        
        return JSON.parse(file.body);
      }
    } catch (error) {
      console.error('Cloud sync failed:', error);
    }
  }
}
```

## 方案三：Electron 桌面应用

### 技术栈
- **框架**: Electron + React + TypeScript
- **构建**: Electron Builder
- **存储**: 本地 JSON 文件 + SQLite
- **UI**: Ant Design

### 主进程配置
```typescript
// main.ts
import { app, BrowserWindow, Menu, ipcMain } from 'electron';
import * as path from 'path';

class MilanOutlineApp {
  private mainWindow: BrowserWindow;
  
  constructor() {
    app.whenReady().then(() => this.createWindow());
    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') app.quit();
    });
  }
  
  private createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 1200,
      height: 800,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: path.join(__dirname, 'preload.js')
      }
    });
    
    this.mainWindow.loadFile('dist/index.html');
    this.setupMenu();
    this.setupIPC();
  }
  
  private setupMenu() {
    const template = [
      {
        label: '文件',
        submenu: [
          { label: '新建大纲', accelerator: 'CmdOrCtrl+N', click: () => this.newOutline() },
          { label: '保存', accelerator: 'CmdOrCtrl+S', click: () => this.saveOutline() },
          { type: 'separator' },
          { label: '退出', accelerator: 'CmdOrCtrl+Q', click: () => app.quit() }
        ]
      }
    ];
    
    Menu.setApplicationMenu(Menu.buildFromTemplate(template as any));
  }
  
  private setupIPC() {
    ipcMain.handle('save-outline', async (event, data) => {
      // 保存到本地文件
      const fs = require('fs').promises;
      const filePath = path.join(app.getPath('userData'), 'outlines.json');
      await fs.writeFile(filePath, JSON.stringify(data, null, 2));
    });
    
    ipcMain.handle('load-outlines', async () => {
      // 从本地文件加载
      const fs = require('fs').promises;
      const filePath = path.join(app.getPath('userData'), 'outlines.json');
      try {
        const data = await fs.readFile(filePath, 'utf8');
        return JSON.parse(data);
      } catch {
        return [];
      }
    });
  }
}

new MilanOutlineApp();
```

## 方案四：静态网站 + 云存储

### 技术栈
- **框架**: React + TypeScript + Vite
- **部署**: Vercel/Netlify
- **存储**: Firebase/Supabase (免费层)
- **认证**: Firebase Auth

### 简化的云存储
```typescript
// firebase-storage.ts
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, doc, setDoc, getDocs } from 'firebase/firestore';

class FirebaseStorage {
  private db: any;
  
  constructor() {
    const app = initializeApp(firebaseConfig);
    this.db = getFirestore(app);
  }
  
  async saveOutline(userId: string, outline: Outline): Promise<void> {
    const docRef = doc(this.db, 'users', userId, 'outlines', outline.id);
    await setDoc(docRef, outline);
  }
  
  async loadOutlines(userId: string): Promise<Outline[]> {
    const querySnapshot = await getDocs(
      collection(this.db, 'users', userId, 'outlines')
    );
    
    return querySnapshot.docs.map(doc => doc.data() as Outline);
  }
}
```

## 推荐方案：浏览器插件

### 优势
1. **零配置启动** - 安装即用
2. **轻量级** - 不需要服务器
3. **集成度高** - 可以在任何网页使用
4. **离线工作** - 完全本地存储
5. **快捷键支持** - 提高使用效率

### 核心组件示例

#### 弹窗界面 (popup.tsx)
```typescript
// src/popup/popup.tsx
import React, { useEffect } from 'react';
import { Button, List, Input, Space, Typography } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import { useStore } from '../hooks/useStore';

const { Title, Text } = Typography;
const { Search } = Input;

export const Popup: React.FC = () => {
  const {
    outlines,
    currentOutlineId,
    searchQuery,
    loadData,
    createOutline,
    setCurrentOutline,
    deleteOutline,
    setSearchQuery
  } = useStore();

  useEffect(() => {
    loadData();
  }, []);

  const handleCreateOutline = async () => {
    const title = prompt('请输入大纲标题:');
    if (title) {
      await createOutline(title);
    }
  };

  const handleOpenSidebar = () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      chrome.tabs.sendMessage(tabs[0].id!, { type: 'TOGGLE_SIDEBAR' });
    });
  };

  const filteredOutlines = outlines.filter(outline =>
    outline.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div style={{ width: 350, padding: 16 }}>
      <Title level={4}>MilanOutline</Title>

      <Space direction="vertical" style={{ width: '100%' }}>
        <Search
          placeholder="搜索大纲..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          style={{ marginBottom: 16 }}
        />

        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={handleCreateOutline}
          block
        >
          创建新大纲
        </Button>

        {currentOutlineId && (
          <Button
            type="default"
            onClick={handleOpenSidebar}
            block
          >
            打开侧边栏 (Ctrl+Shift+O)
          </Button>
        )}

        <List
          size="small"
          dataSource={filteredOutlines}
          renderItem={(outline) => (
            <List.Item
              actions={[
                <Button
                  type="text"
                  size="small"
                  icon={<EditOutlined />}
                  onClick={() => setCurrentOutline(outline.id)}
                />,
                <Button
                  type="text"
                  size="small"
                  danger
                  icon={<DeleteOutlined />}
                  onClick={() => deleteOutline(outline.id)}
                />
              ]}
            >
              <List.Item.Meta
                title={
                  <Text
                    strong={outline.id === currentOutlineId}
                    style={{ cursor: 'pointer' }}
                    onClick={() => setCurrentOutline(outline.id)}
                  >
                    {outline.title}
                  </Text>
                }
                description={`${outline.nodes.length} 个节点`}
              />
            </List.Item>
          )}
        />
      </Space>
    </div>
  );
};
```

#### 内容脚本 (content.tsx)
```typescript
// src/content/index.ts
import React from 'react';
import { createRoot } from 'react-dom/client';
import { OutlineSidebar } from './OutlineSidebar';

class ContentScript {
  private sidebar: HTMLElement | null = null;
  private root: any = null;
  private isVisible = false;

  constructor() {
    this.init();
    this.setupMessageListener();
  }

  private init() {
    // 创建侧边栏容器
    this.sidebar = document.createElement('div');
    this.sidebar.id = 'milan-outline-sidebar';
    this.sidebar.style.cssText = `
      position: fixed;
      top: 0;
      right: -400px;
      width: 400px;
      height: 100vh;
      background: white;
      box-shadow: -2px 0 10px rgba(0,0,0,0.1);
      z-index: 2147483647;
      transition: right 0.3s ease;
      border-left: 1px solid #e8e8e8;
    `;

    document.body.appendChild(this.sidebar);

    // 渲染 React 组件
    this.root = createRoot(this.sidebar);
    this.root.render(<OutlineSidebar onClose={() => this.toggle()} />);
  }

  private setupMessageListener() {
    chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
      switch (message.type) {
        case 'TOGGLE_SIDEBAR':
          this.toggle();
          break;
        case 'ADD_NODE':
          // 触发添加节点
          break;
      }
    });
  }

  private toggle() {
    this.isVisible = !this.isVisible;
    if (this.sidebar) {
      this.sidebar.style.right = this.isVisible ? '0px' : '-400px';
    }
  }
}

// 初始化
new ContentScript();
```

### 安装使用指南

#### 1. 运行创建脚本
```powershell
.\create-extension.ps1
```

#### 2. 安装依赖并构建
```bash
npm install
npm run build
```

#### 3. 在 Chrome 中安装
1. 打开 Chrome 扩展管理页面 (`chrome://extensions/`)
2. 开启"开发者模式"
3. 点击"加载已解压的扩展程序"
4. 选择项目的 `dist` 文件夹

#### 4. 使用插件
- 点击工具栏图标打开弹窗
- 使用 `Ctrl+Shift+O` 切换侧边栏
- 使用 `Ctrl+Shift+N` 添加新节点

### 优势总结

✅ **零配置启动** - 安装即用，无需服务器
✅ **轻量级** - 打包后仅几百KB
✅ **离线工作** - 完全本地存储
✅ **快捷键支持** - 提高使用效率
✅ **跨网站使用** - 在任何页面都能使用
✅ **数据安全** - 数据存储在本地

这种浏览器插件方案最适合您的需求：启动即用、轻量级、无需服务器配置。您觉得这个方案如何？
