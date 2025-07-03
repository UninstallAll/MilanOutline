// Content Script for MilanNote Outline Extension

interface OutlineItem {
  id: string
  title: string
  content: string
  level: number
  children: OutlineItem[]
}

class MilanNoteOutlineExtractor {
  private generateId(): string {
    return Math.random().toString(36).substr(2, 9)
  }

  private extractTextContent(element: Element): string {
    return element.textContent?.trim() || ''
  }

  private analyzeContent(): OutlineItem[] {
    const outline: OutlineItem[] = []
    
    try {
      // 查找MilanNote的主要内容区域
      const contentSelectors = [
        '[data-testid="board"]',
        '.board-container',
        '.notes-container',
        '.board-content',
        'main',
        '#app'
      ]

      let mainContent: Element | null = null
      for (const selector of contentSelectors) {
        mainContent = document.querySelector(selector)
        if (mainContent) break
      }

      if (!mainContent) {
        console.log('未找到MilanNote主内容区域')
        return outline
      }

      // 查找笔记卡片和文本内容
      const noteElements = mainContent.querySelectorAll([
        '[data-testid*="note"]',
        '.note-card',
        '.text-note',
        '.note-item',
        '.card',
        'div[contenteditable="true"]',
        'textarea',
        'input[type="text"]'
      ].join(', '))

      console.log(`找到 ${noteElements.length} 个潜在的笔记元素`)

      noteElements.forEach((element, index) => {
        const text = this.extractTextContent(element)
        if (text && text.length > 3) {
          const item: OutlineItem = {
            id: this.generateId(),
            title: text.length > 50 ? text.substring(0, 50) + '...' : text,
            content: text,
            level: this.determineLevel(element),
            children: []
          }
          outline.push(item)
        }
      })

      // 如果没有找到笔记，尝试查找其他文本内容
      if (outline.length === 0) {
        const textElements = mainContent.querySelectorAll('h1, h2, h3, h4, h5, h6, p, div')
        textElements.forEach((element) => {
          const text = this.extractTextContent(element)
          if (text && text.length > 10 && !this.isUIElement(element)) {
            const item: OutlineItem = {
              id: this.generateId(),
              title: text.length > 50 ? text.substring(0, 50) + '...' : text,
              content: text,
              level: this.determineLevel(element),
              children: []
            }
            outline.push(item)
          }
        })
      }

      // 按层级组织大纲
      return this.organizeOutline(outline)

    } catch (error) {
      console.error('提取大纲时出错:', error)
      return outline
    }
  }

  private determineLevel(element: Element): number {
    const tagName = element.tagName.toLowerCase()
    
    // 根据HTML标签确定层级
    if (tagName.match(/^h[1-6]$/)) {
      return parseInt(tagName.charAt(1))
    }
    
    // 根据CSS类名或数据属性确定层级
    const classList = element.className
    if (classList.includes('title') || classList.includes('heading')) {
      return 1
    }
    if (classList.includes('subtitle') || classList.includes('subheading')) {
      return 2
    }
    
    // 根据嵌套深度确定层级
    let level = 1
    let parent = element.parentElement
    while (parent && level < 4) {
      if (parent.classList.contains('note') || parent.classList.contains('card')) {
        level++
      }
      parent = parent.parentElement
    }
    
    return Math.min(level, 3)
  }

  private isUIElement(element: Element): boolean {
    const classList = element.className.toLowerCase()
    const uiKeywords = ['button', 'menu', 'nav', 'toolbar', 'header', 'footer', 'sidebar']
    return uiKeywords.some(keyword => classList.includes(keyword))
  }

  private organizeOutline(items: OutlineItem[]): OutlineItem[] {
    // 简单的层级组织，可以根据需要进一步优化
    const organized: OutlineItem[] = []
    const stack: OutlineItem[] = []

    items.forEach(item => {
      while (stack.length > 0 && stack[stack.length - 1].level >= item.level) {
        stack.pop()
      }

      if (stack.length === 0) {
        organized.push(item)
      } else {
        stack[stack.length - 1].children.push(item)
      }

      stack.push(item)
    })

    return organized
  }

  public extractOutline(): OutlineItem[] {
    console.log('开始提取MilanNote页面大纲...')
    const outline = this.analyzeContent()
    console.log('提取到的大纲:', outline)
    return outline
  }
}

// 监听来自popup的消息
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'generateOutline') {
    const extractor = new MilanNoteOutlineExtractor()
    const outline = extractor.extractOutline()
    sendResponse({ outline })
  }
  return true
})

// 页面加载完成后初始化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    console.log('MilanOutline Content Script 已加载')
  })
} else {
  console.log('MilanOutline Content Script 已加载')
}
