# MilanOutline - MilanNote 大纲整理助手

一个轻量级的浏览器插件，为 MilanNote 提供智能大纲整理和总结功能。

## 功能特点

- 🎯 **智能大纲提取**: 自动分析 MilanNote 页面内容，生成结构化大纲
- 📋 **实时预览**: 在弹窗中查看生成的大纲结构
- 🎨 **美观界面**: 现代化的用户界面设计
- ⚡ **轻量快速**: 基于浏览器插件，无需额外安装

## 安装方法

### 开发模式安装

1. **克隆项目**
   ```bash
   git clone https://github.com/UninstallAll/MilanOutline.git
   cd MilanOutline
   ```

2. **安装依赖**
   ```bash
   npm install
   ```

3. **构建插件**
   ```bash
   npm run build
   ```

4. **在 Chrome 中加载插件**
   - 打开 Chrome 浏览器
   - 访问 `chrome://extensions/`
   - 开启右上角的"开发者模式"
   - 点击"加载已解压的扩展程序"
   - 选择项目中的 `dist` 文件夹

### 开发模式（实时预览）

```bash
npm run dev
```

这将启动文件监听模式，当你修改源代码时会自动重新构建。修改后需要在 Chrome 扩展页面手动重新加载插件。

## 使用方法

1. **访问 MilanNote**
   - 打开 [milanote.com](https://milanote.com) 或 [app.milanote.com](https://app.milanote.com)
   - 确保页面完全加载

2. **生成大纲**
   - 点击浏览器工具栏中的 MilanOutline 图标
   - 在弹出的窗口中点击"生成大纲"按钮
   - 查看自动生成的页面大纲

3. **查看结果**
   - 大纲会按层级结构显示
   - 不同层级用不同颜色和缩进表示
   - 点击大纲项可以查看详细内容

## 项目结构

```
MilanOutline/
├── src/
│   ├── popup/          # 弹窗界面
│   │   ├── Popup.tsx   # 主要弹窗组件
│   │   ├── index.tsx   # 入口文件
│   │   └── popup.css   # 样式文件
│   ├── content/        # 内容脚本
│   │   ├── index.ts    # 页面内容分析
│   │   └── content.css # 注入样式
│   └── background/     # 后台脚本
│       └── index.ts    # 后台服务
├── public/
│   ├── manifest.json   # 插件配置
│   └── icons/          # 图标文件
├── dist/               # 构建输出
└── package.json        # 项目配置
```

## 开发说明

### 技术栈

- **React 19**: 用户界面框架
- **TypeScript**: 类型安全的 JavaScript
- **Vite**: 现代化构建工具
- **Chrome Extension API**: 浏览器插件接口

### 构建命令

- `npm run dev`: 开发模式（文件监听）
- `npm run build`: 生产构建
- `npm run type-check`: TypeScript 类型检查

### 调试技巧

1. **查看控制台日志**
   - 右键点击插件图标 → "检查弹出式窗口"
   - 在 MilanNote 页面按 F12 → Console 标签

2. **重新加载插件**
   - 修改代码后运行 `npm run build`
   - 在 `chrome://extensions/` 页面点击插件的刷新按钮

3. **检查权限**
   - 确保插件有访问 MilanNote 网站的权限
   - 检查 manifest.json 中的 host_permissions

## 支持的网站

- milanote.com
- app.milanote.com

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

🎉 享受你的轻量级大纲管理之旅！
