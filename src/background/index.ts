// Background Script for MilanNote Outline Extension

// 插件安装时的初始化
chrome.runtime.onInstalled.addListener((details) => {
  console.log('MilanOutline 插件已安装/更新', details)
  
  // 设置默认配置
  chrome.storage.sync.set({
    autoGenerate: false,
    outlineDepth: 3,
    includeImages: false
  })
})

// 监听标签页更新
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.url) {
    // 检查是否是MilanNote页面
    if (tab.url.includes('milanote.com')) {
      console.log('检测到MilanNote页面:', tab.url)
      
      // 可以在这里添加自动功能，比如自动生成大纲
      chrome.storage.sync.get(['autoGenerate'], (result) => {
        if (result.autoGenerate) {
          // 自动生成大纲的逻辑
          setTimeout(() => {
            chrome.tabs.sendMessage(tabId, { action: 'autoGenerateOutline' })
          }, 2000) // 等待页面完全加载
        }
      })
    }
  }
})

// 处理来自content script或popup的消息
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('Background收到消息:', request)
  
  switch (request.action) {
    case 'saveOutline':
      // 保存大纲到存储
      chrome.storage.local.set({
        [`outline_${Date.now()}`]: request.outline
      }, () => {
        sendResponse({ success: true })
      })
      return true
      
    case 'getOutlineHistory':
      // 获取历史大纲
      chrome.storage.local.get(null, (items) => {
        const outlines = Object.keys(items)
          .filter(key => key.startsWith('outline_'))
          .map(key => ({
            id: key,
            timestamp: parseInt(key.replace('outline_', '')),
            outline: items[key]
          }))
          .sort((a, b) => b.timestamp - a.timestamp)
        
        sendResponse({ outlines })
      })
      return true
      
    case 'deleteOutline':
      // 删除指定大纲
      chrome.storage.local.remove(request.outlineId, () => {
        sendResponse({ success: true })
      })
      return true
      
    default:
      sendResponse({ error: 'Unknown action' })
  }
})

// 右键菜单（可选功能）
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'generateOutline' && tab?.id) {
    chrome.tabs.sendMessage(tab.id, { action: 'generateOutline' })
  }
})

// 创建右键菜单
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'generateOutline',
    title: '生成页面大纲',
    contexts: ['page'],
    documentUrlPatterns: ['*://milanote.com/*', '*://app.milanote.com/*']
  })
})

// 快捷键处理
chrome.commands.onCommand.addListener((command) => {
  if (command === 'generate-outline') {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      const tab = tabs[0]
      if (tab?.id && tab.url?.includes('milanote.com')) {
        chrome.tabs.sendMessage(tab.id, { action: 'generateOutline' })
      }
    })
  }
})

console.log('MilanOutline Background Script 已启动')
