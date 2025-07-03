import React, { useState, useEffect } from 'react'

interface OutlineItem {
  id: string
  title: string
  content: string
  level: number
  children: OutlineItem[]
}

const Popup: React.FC = () => {
  const [isConnected, setIsConnected] = useState(false)
  const [outline, setOutline] = useState<OutlineItem[]>([])
  const [isGenerating, setIsGenerating] = useState(false)

  useEffect(() => {
    // 检查是否在MilanNote页面
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      const currentTab = tabs[0]
      if (currentTab?.url?.includes('milanote.com')) {
        setIsConnected(true)
      }
    })
  }, [])

  const generateOutline = async () => {
    if (!isConnected) return
    
    setIsGenerating(true)
    try {
      // 向content script发送消息
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true })
      if (tab.id) {
        const response = await chrome.tabs.sendMessage(tab.id, { 
          action: 'generateOutline' 
        })
        if (response?.outline) {
          setOutline(response.outline)
        }
      }
    } catch (error) {
      console.error('生成大纲失败:', error)
    } finally {
      setIsGenerating(false)
    }
  }

  const renderOutlineItem = (item: OutlineItem, index: number) => (
    <div key={item.id} className={`outline-item level-${item.level}`}>
      <div className="outline-title">{item.title}</div>
      {item.content && (
        <div className="outline-content">{item.content}</div>
      )}
      {item.children.length > 0 && (
        <div className="outline-children">
          {item.children.map((child, childIndex) => 
            renderOutlineItem(child, childIndex)
          )}
        </div>
      )}
    </div>
  )

  return (
    <div className="popup-container">
      <header className="popup-header">
        <h1>MilanOutline</h1>
        <div className={`status ${isConnected ? 'connected' : 'disconnected'}`}>
          {isConnected ? '已连接 MilanNote' : '请打开 MilanNote 页面'}
        </div>
      </header>

      <main className="popup-main">
        {isConnected ? (
          <>
            <button 
              className="generate-btn"
              onClick={generateOutline}
              disabled={isGenerating}
            >
              {isGenerating ? '生成中...' : '生成大纲'}
            </button>

            {outline.length > 0 && (
              <div className="outline-container">
                <h3>页面大纲</h3>
                <div className="outline-list">
                  {outline.map((item, index) => renderOutlineItem(item, index))}
                </div>
              </div>
            )}
          </>
        ) : (
          <div className="not-connected">
            <p>请在 MilanNote 页面中使用此插件</p>
            <p>支持的网站：</p>
            <ul>
              <li>milanote.com</li>
              <li>app.milanote.com</li>
            </ul>
          </div>
        )}
      </main>
    </div>
  )
}

export default Popup
