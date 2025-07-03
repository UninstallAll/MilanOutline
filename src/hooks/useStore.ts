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
